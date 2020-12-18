module RuneRb::Network
  # Represents a host endpoint which accepts sockets and alerts their sessions to populate their buffers via an nio selector.
  class Endpoint
    using RuneRb::System::Patches::IntegerOverrides
    include RuneRb::System::Log

    # @return [RuneRb::Game::World::Instance] the World associated with the Endpoint
    attr :world

    # Called when a new Endpoint is created.
    # @param config [Hash] the configuration for the controller.
    def initialize(config = {})
      raise 'No RuneRb::Game::World::Instance provided to the Endpoint!' unless config[:world]

      @world = config[:world]
      @host = config[:host] || RuneRb::GLOBAL[:RRB_HOST]
      @port = config[:port] || RuneRb::GLOBAL[:RRB_PORT]
      @server = TCPServer.new(@host || '0.0.0.0', @port || 43_594)
      @selector = NIO::Selector.new
      @selector.register(@server, :r).value = -> { register_sessions }
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      @sessions = {}
    end

    def run
      log "Endpoint deployed: #{@host}:#{@port} @ #{@start[:stamp]}"
      loop { @selector.select { |monitor| monitor.value.call } }
    rescue StandardError => e
      shutdown(graceful: false)
      err 'An error occurred while deploying Endpoint!', e
      puts e.backtrace
    rescue Interrupt
      shutdown(graceful: true)
      log! "Up-time: #{up_time.to_i.to_ftime}"
    end

    # Shuts the endpoint down.
    # @param graceful [Boolean] gracefully shut down?
    def shutdown(graceful: true)
      # Release all session contexts from the world.
      @sessions.each_value { |session| @world.release(session.context) } if graceful
    ensure
      # Ensure the server is closed.
      @server&.close
      # Ensure all sessions are disconnected.
      @sessions.each_value(&:disconnect)
    end

    # The current up-time for the server.
    def up_time
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time] || Time.now)).round(3)
    end

    private

    # Accepts a new socket connection via TCPServer#accept_nonblock and registers it with the Endpoint#clients hash. Sockets that are accepted are registered with the Endpoint#selector with an :r (readable) interest. The returned monitor object is passed a proc to execute `Endpoint#touch_clients` which is called when an interest is raised for the corresponding socket (it becomes readable/writable).
    def register_sessions
      socket = @server.accept_nonblock
      @selector.register(socket, :r).value = -> { process_session(socket) }
      @sessions[socket] = RuneRb::Network::Session.new(socket)
      log "Registered new socket for #{@sessions[socket].ip}"
    rescue StandardError => e
      err 'An error occurred while registering sessions!', e
      puts e.backtrace
    end

    # Unregisters a socket from the selector and removes it's reference from the system client list.
    def unregister(session)
      @sessions.delete(session.socket)
      log RuneRb::COL.green("De-registered socket for #{session.ip}")
    rescue StandardError => e
      err 'An error occurred while unregistering session!',e
      puts e.backtrace
    end

    # Processes active sessions and removes inactive sessions.
    def process_session(socket)
      return unless @sessions[socket]

      log! "Up-time: #{up_time}" if up_time % 600 == 0 && RuneRb::GLOBAL[:RRB_DEBUG]
      @sessions[socket].update
      @world.login(@sessions[socket]) if @sessions[socket].status[:auth] == :PENDING_WORLD
      unregister(@sessions[socket]) unless @sessions[socket].status[:active]
    rescue StandardError => e
      err 'An error occurred while processing session!', e
      puts e.backtrace
    end
  end
end