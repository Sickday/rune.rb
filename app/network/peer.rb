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
        @status[:authenticated] ? next_frame : authenticate
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

    # @param data [String, StringIO] the the data to write.
    def write(data = '')
      @out[:raw] << data
    end

    alias << write

    def flush
      @socket.write_nonblock(@out.each_with_object('') { |str, frame| str << frame.compile }) unless @out.empty?
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
  end
end