module RuneRb::Net
  class Session
    include RuneRb::Internal::Log
    include RuneRb::Net::LoginHelper
    include RuneRb::Net::FrameWriter
    include RuneRb::Net::FrameReader

    attr :ip, :id, :status, :socket, :context

    # Called after a new Session object is initialized.
    # @param endpoint [RuneRb::Net::Endpoint]
    def initialize(socket, endpoint)
      @socket = socket
      @endpoint = endpoint
      @status = { auth: :PENDING_CONNECTION, active: true }
      @ip = @socket.peeraddr.last
      @in = ''
      @id = Druuid.gen
    rescue StandardError => e
      err! 'An error occurred while attaching session to Endpoint!'
      puts e
      puts e.backtrace
    end

    # Registers a context to the session
    # @param context [RuneRb::Entity::Context] the Context to register
    def register(context)
      @context = context
    end

    # Writes data to the Session#socket object via Socket#write_nonblock
    # @param data [String, StringIO] the raw data to write to the socket.
    def send_data(data)
      @socket.write_nonblock(data)
    rescue EOFError
      err 'Peer disconnected!' if RuneRb::DEBUG
      disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!' if RuneRb::DEBUG
      disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!' if RuneRb::DEBUG
      disconnect
    rescue Errno::EPIPE
      err 'PIPE MACHINE BR0kE!1' if RuneRb::DEBUG
      disconnect
    end

    # Reads data into the Session#in
    def receive_data
      @in << @socket.read_nonblock(5192)
      case @status[:auth]
      when :PENDING_CONNECTION
        read_connection
      when :PENDING_BLOCK
        read_block
      when :LOGGED_IN
        next_frame if @in.size >= 3
      else
        read_connection
      end
    rescue IO::EAGAINWaitReadable
      err 'Socket has no data' if RuneRb::DEBUG
      nil
    rescue EOFError
      err 'Reached EOF!' if RuneRb::DEBUG
      disconnect
    rescue IOError
      err 'Stream has been closed!' if RuneRb::DEBUG
      disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!' if RuneRb::DEBUG
      disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!' if RuneRb::DEBUG
      disconnect
    rescue Errno::EPIPE
      err 'PIPE MACHINE BR0kE!1' if RuneRb::DEBUG
      disconnect
    end

    # This function is called every 600 ms.
    # The client expects the player synchronization frame along with a state block to be written every 600ms.
    def pulse
      @context.pre_pulse
      write(:sync, context: @context) if @status[:auth] == :LOGGED_IN && @status[:active] && @context.world
      @context.post_pulse
    rescue StandardError => e
      err! 'An error occurred during Session pulse!', e, e.backtrace
    end

    # Gracefully disconnects the session by release it's context, updating the Session#status, and calling Session#close to ensure the endpoint releases the session's socket.
    def disconnect
      @status[:active] = false
      @status[:auth] = :LOGGED_OUT
      @context&.world&.release(@context)
    rescue StandardError => e
      err 'An error occurred while disconnecting the session', e
      puts e.backtrace
    ensure
      close
    end

    private

    # Closes the underlying socket and deregisters the session from the endpoint.
    def close
      @endpoint.deregister(self, @socket)
      @socket.close unless @socket.closed?
    end
  end
end