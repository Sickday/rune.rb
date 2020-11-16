module RuneRb::Network
  class Peer
    include RuneRb::Types::Loggable
    include RuneRb::Network::AuthenticationHelper
    include RuneRb::Network::FrameReader
    include RuneRb::Network::FrameWriter

    attr :ip, :id, :status, :socket

    # Called when a new Peer object is created.
    # @param socket [Socket] the socket for the peer.
    def initialize(socket, endpoint)
      @socket, @ip = socket, socket.peeraddr.last
      @status = { active: true, authenticated: false }
      @endpoint = endpoint
      @in = ''
      @out = []
      @id = Druuid.gen
    end

    # Reads data into the Peer#in
    def receive_data
      if @status[:active]
        if @status[:authenticated] == :LOGGED_IN
          @in << @socket.read_nonblock(5192)
          @context ||= RuneRb::Entity::Context.new(self, @profile)
          next_frame if @in.size >= 3
        else
          authenticate
        end
      end
    rescue IO::EAGAINWaitReadable => e
      err 'Socket has no data'
      puts e
      puts e.backtrace
    rescue EOFError
      err 'Reached EOF!'
      @status[:authenticated] == :LOGGED_IN ? write_disconnect : disconnect
    rescue IOError
      err 'Stream has been closed!'
      @status[:authenticated] == :LOGGED_IN ? write_disconnect : disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!'
      @status[:authenticated] == :LOGGED_IN ? write_disconnect : disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!'
      @status[:authenticated] == :LOGGED_IN ? write_disconnect : disconnect
    rescue Errno::EPIPE
      err 'PIPE MACHINE BR0kE!1'
      disconnect
    end

    def send_data(data)
      @socket.write_nonblock(data)
    rescue EOFError
      err 'Peer disconnected!'
      @status[:authenticated] == :LOGGED_IN ? write_disconnect : disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!'
      @status[:authenticated] == :LOGGED_IN ? write_disconnect : disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!'
      @status[:authenticated] == :LOGGED_IN ? write_disconnect : disconnect
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
      write_login if @status[:authenticated] == :PENDING_LOGIN
      write_mock_update if @context && @status[:active] && @status[:authenticated] == :LOGGED_IN
      @context&.reset_flags
    end

    # Close the socket.
    def disconnect
      @socket.close
      @status[:active] = false
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