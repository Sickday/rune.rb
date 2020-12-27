module RuneRb::Network
  class Session
    using RuneRb::System::Patches::IntegerRefinements

    include RuneRb::System::Log
    include RuneRb::Network::LoginHelper
    include RuneRb::Network::FrameWriter
    include RuneRb::Network::FrameReader

    attr :ip, :id, :status, :socket, :context, :start

    # Called after a new Session object is initialized.
    def initialize(socket)
      @socket = socket
      @status = { auth: :PENDING_CONNECTION, active: true }
      @ip = @socket.addr.last
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      @id = Druuid.gen
    rescue StandardError => e
      err! 'An error occurred while attaching session to Endpoint!'
      puts e
      puts e.backtrace
    end

    # Registers a context to the session
    # @param context [RuneRb::Game::Entity::Context] the Context to register
    def register(context)
      @context = context
    end

    # Writes data to the Session#socket object via Socket#write_nonblock
    # @param data [String, StringIO] the raw data to write to the socket.
    def send_data(data)
      @socket.write_nonblock(data)
    rescue EOFError
      err 'Peer disconnected!' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    rescue Errno::EPIPE
      err 'PIPE MACHINE BR0kE!1' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    end

    # Reads data into the Session#in
    def update(task: Async::Task.current)
      task.async do |sub|
        case @status[:auth]
        when :PENDING_CONNECTION
          read_connection(task: sub)
        when :PENDING_BLOCK
          read_block(task: sub)
        when :LOGGED_IN
          next_frame
        else
          read_connection(task: sub)
        end
      end
    rescue IO::EAGAINWaitReadable
      err 'Socket has no data' if RuneRb::GLOBAL[:RRB_DEBUG]
      nil
    rescue EOFError
      err 'Reached EOF!' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    rescue IOError
      err 'Stream has been closed!' if RuneRb::GLOBAL[:RRB_DEBUG]
      #disconnect
    rescue Errno::ECONNRESET
      err 'Peer reset connection!' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    rescue Errno::ECONNABORTED
      err 'Peer aborted connection!' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    rescue Errno::EPIPE
      err 'PIPE MACHINE BR0kE!1' if RuneRb::GLOBAL[:RRB_DEBUG]
      disconnect
    end

    # Gracefully disconnects the session by release it's context, updating the Session#status, and calling Session#close to ensure the endpoint releases the session's socket.
    def disconnect
      @status[:active] = false
      @status[:auth] = :LOGGED_OUT
    rescue StandardError => e
      err 'An error occurred while disconnecting the session', e
      puts e.backtrace
    ensure
      close
    end

    # The current up-time for the session.
    def up_time
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time] || Time.now)).round(3)
    end

    private

    # Closes the underlying socket.
    def close
      @socket.close unless @socket.closed?
      log! "Session duration: #{up_time.to_i.to_ftime}"
    end
  end
end