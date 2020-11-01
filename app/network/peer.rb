module RuneRb::Network
  class Peer
    include RuneRb::Types::Loggable
    include RuneRb::Network::AuthenticationHelper
    include RuneRb::Network::FrameReader
    include RuneRb::Network::FrameWriter

    attr :ip, :id, :status

    # Called when a new Peer object is created.
    # @param socket [Socket] the socket for the peer.
    def initialize(socket)
      @socket, @ip = socket, socket.peeraddr[-1]
      @status = { active: true, authenticated: false }
      @in = { raw: '', parsed: [] }
      @out = { raw: '', encoded: [] }
      @login = RuneRb::Network::JReadableBuffer.new
      @id = Druuid.gen
    end

    # Reads at most 5,120 bytes into the Peer#in object.
    def receive_data
      if @status[:active]
        if @status[:authenticated]
          @in[:raw] << @socket.read_nonblock(64)
          read_frames
        else
          @login << @socket.read_nonblock(256)
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

    def write_now
      @socket.write_nonblock(@out[:raw])
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

    # @param data [String, StringIO] the the data to write.
    def write(data = '')
      @out[:raw] << data
      write_now
    end

    alias << write

    def flush
      unless @out[:encoded].empty?
        payload = ''
        @out[:encoded].each { |frame| payload << frame.compile }
        @socket.write_nonblock(payload)
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
      @socket.close
      @status[:active] = false
    end
  end
end