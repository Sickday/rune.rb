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
      @socket, @ip = socket, socket.peeraddr[-1]
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
    rescue IO::EAGAINWaitReadable
      err 'Socket has no data'
      nil
    rescue EOFError
      err 'Reached EOF!'
      disconnect
    rescue IOError
      err 'Stream has been closed!'
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

    def send_data(data)
      @socket.write_nonblock(data)
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
      @socket.write_nonblock(encode_frame(frame).compile)
    rescue EOFError
      err 'Peer disconnected!'
      write_disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!'
      write_disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!'
      write_disconnect
    rescue Errno::EPIPE
      err 'PIPE MACHINE BR0kE!1'
      write_disconnect
    end

    alias << write_frame

    def flush
      write_login if @status[:authenticated] == :PENDING_LOGIN
      write_mock_update if @context && @status[:active]
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

    # Close the socket.
    def disconnect
      @socket.close
      @status[:active] = false
      @endpoint.deregister(self, @socket)
    end

    # Encodes a frame using the Peer#cipher.
    # @param frame [RuneRb::Network::Frame] the frame to encode.
    def encode_frame(frame)
      raise 'Invalid cipher for client!' unless @cipher

      frame.header[:op_code] += @cipher[:encryptor].next_value & 0xFF
      log "Encoding frame: #{frame.inspect}" if RuneRb::DEBUG
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