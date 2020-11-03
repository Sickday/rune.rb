module RuneRb::Network
  class Peer
    include RuneRb::Types::Loggable
    include RuneRb::Network::AuthenticationHelper
    include RuneRb::Network::FrameReader
    include RuneRb::Network::FrameWriter

    attr :ip, :id, :status, :socket

    # Called when a new Peer object is created.
    # @param socket [Socket] the socket for the peer.
    def initialize(socket)
      @socket, @ip = socket, socket.peeraddr[-1]
      @status = { active: true, authenticated: false }
      @in = ''
      @out = []
      @id = Druuid.gen
    end

    # Reads data into the Peer#in
    def receive_data
      if @status[:active]
        if @status[:authenticated]
          next_frame
          @context ||= RuneRb::Entity::Context.new(self, @profile)
        else
          authenticate
        end
      end
    rescue IO::EAGAINWaitReadable
      err 'Socket has no data'
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
      @out << encode_frame(frame)
    end

    alias << write_frame

    def flush
      write_mock_update if @context
      if @status[:active] && !@out.empty?
        @socket.write_nonblock(@out.first.compile)
        @out.delete(@out.first)
      end
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
      @status[:active] = false
      @socket.close
    end

    # Encodes a frame using the Peer#cipher.
    # @param frame [RuneRb::Network::Frame] the frame to encode.
    def encode_frame(frame)
      raise 'Invalid cipher for client!' unless @cipher

      log "Encoding frame: #{frame.inspect}"
      frame.header[:op_code] += @cipher[:encryptor].next_value & 0xFF
      frame
    end
  end
end