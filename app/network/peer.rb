module RuneRb::Network
  class Peer
    include RuneRb::Types::Loggable
    include RuneRb::Network::AuthenticationHelper
    include RuneRb::Network::FrameReader
    include RuneRb::Network::FrameWriter

    attr :ip, :id, :status, :socket, :profile, :context

    # Called when a new Peer object is created.
    # @param socket [Socket] the socket for the peer.
    def initialize(socket, endpoint)
      @socket, @ip = socket, socket.peeraddr.last
      @status = { active: true, authenticated: :PENDING_CONNECTION }
      @endpoint = endpoint
      @in = ''
      @out = []
      @id = Druuid.gen
    end

    # Registers a context to the peer and confirms the status to be logged in
    # @param context [RuneRb::Entity::Context] the Context to register
    def register_context(context)
      @context = context
      @status[:authenticated] = :LOGGED_IN
      log 'Registered context'
    end

    # Reads data into the Peer#in
    def receive_data
      if @status[:active]
        case @status[:authenticated]
        when :PENDING_CONNECTION
          @connection_frame = RuneRb::Network::InFrame.new(-1)
          @connection_frame.push(@socket.read_nonblock(2))

          read_connection
        when :PENDING_BLOCK
          @login_frame = RuneRb::Network::InFrame.new(-1)
          @login_frame.push(@socket.read_nonblock(96))

          read_block
        when :LOGGED_IN
          @in << @socket.read_nonblock(5192) if @status[:active]
          next_frame if @in.size >= 3
        else read_connection
        end
      else
        disconnect
      end
    rescue IO::EAGAINWaitReadable => e
      err 'Socket has no data', e, e.backtrace
      disconnect
    rescue EOFError => e
      err 'Reached EOF!', e, e.backtrace
      disconnect
    rescue IOError => e
      err 'Stream has been closed!', e, e.backtrace
      disconnect
    rescue Errno::ECONNRESET => e
      err 'Peer reset connection!', e, e.backtrace
      disconnect
    rescue Errno::ECONNABORTED => e
      err 'Peer aborted connection!', e.backtrace
      disconnect
    rescue Errno::EPIPE => e
      err 'PIPE MACHINE BR0kE!1', e.backtrace
      disconnect
    end

    # Send data through the underlying socket
    # @param data [String, StringIO] the payload to send.
    def send_data(data)
      @socket.write_nonblock(data) if @status[:active]
    rescue EOFError
      err 'Peer disconnected!'
      disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!'
      disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!'
      disconnect
    rescue Errno::EPIPE
      err 'PIPE MACHINE BR0kE!1'
      disconnect
    end

    # @param frame [RuneRb::Network::MetaFrame] the frame to queue for flush
    def write_frame(frame)
      send_data(encode_frame(frame).compile) if @status[:active]
    end

    alias << write_frame

    # Should perhaps rename this to #pulse. The original idea was to flush all pending data, but seeing as all data is immediately written.... well.
    def pulse
      if @context
        write_mock_update if @status[:authenticated] == :LOGGED_IN && @status[:active]
        @context.reset_flags
      elsif @status[:authenticated] == :PENDING_LOGIN
        @endpoint.request_context(self)
      end
    end

    # Close the socket.
    def disconnect
      @socket.close
      @status[:active] = false
      @status[:authenticated] = false
      @endpoint.deregister(self, @socket)
    end

    private

    # Encodes a frame using the Peer#cipher.
    # @param frame [RuneRb::Network::Frame] the frame to encode.
    def encode_frame(frame)
      raise 'Invalid cipher for client!' unless @cipher

      log "Encoding frame: #{frame.inspect}" if RuneRb::DEBUG
      frame.header[:op_code] += @cipher[:encryptor].next_value & 0xFF
      frame
    end

    # Decodes a frame using the Peer#cipher.
    # @param frame [RuneRb::Network::Frame] the frame to decode.
    def decode_frame(frame)
      raise 'Invalid cipher for Peer!' unless @cipher

      frame.header[:op_code] -= @cipher[:decryptor].next_value & 0xFF
      frame.header[:op_code] = frame.header[:op_code] & 0xFF
      frame.header[:length] = RuneRb::Network::Constants::PACKET_MAP[frame.header[:op_code]]
      log "Decoding frame: #{frame.inspect}" if RuneRb::DEBUG
      frame
    end
  end
end