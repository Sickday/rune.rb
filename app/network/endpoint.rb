module RuneRb::Network
  # Represents a host endpoint which accepts sockets and alerts their sessions to populate their buffers via an nio selector.
  class Endpoint
    using RuneRb::System::Patches::IntegerRefinements
    include RuneRb::System::Log

    # @return [RuneRb::Game::World::Instance] the World associated with the Endpoint
    attr :world

    # @return [Integer] the id for the endpoint.
    attr :id

    # Called when a new Endpoint is created.
    # @param config [Hash] the configuration for the controller.
    def initialize(config = {})
      parse_config(config)
      @server = Async::IO::TCPServer.new(@host, @port)
      @selector = NIO::Selector.new
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      @sessions = {}
    end

    def deploy(task: Async::Task.current)
      task.async do |sub|
        log RuneRb::COL.blue("Endpoint listening: #{RuneRb::COL.cyan(@host)}:#{RuneRb::COL.cyan(@port)} @ #{RuneRb::COL.cyan(@start[:stamp])}")
        @selector.register(@server, :r).value = -> { register_sessions(task: sub) }

        loop do
          # Make a select call
          @selector.select { |monitor| monitor.value.call }
          # Yield to the original task to allow execution to continue
          sub.yield
        end
      end
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

    # TODO: update documentation.
    # Accepts a new socket connection via TCPServer#accept_nonblock and registers it with the Endpoint#clients hash. Sockets that are accepted are registered with the Endpoint#selector with an :r (readable) interest. The returned monitor object is passed a proc to execute `Endpoint#touch_clients` which is called when an interest is raised for the corresponding socket (it becomes readable/writable).
    def register_sessions(task: Async::Task.current)
      task.async do |sub|
        peers = @server.accept_nonblock
        task.yield if peers.empty?
        peers.compact!
        peers.each do |socket|
          @selector.register(socket, :r).value = ->{ process_session(sub, socket) }
          @sessions[socket] = RuneRb::Network::Session.new(socket)
          log "Registered new socket for #{@sessions[socket].ip}"
        end
      end
    rescue StandardError => e
      err 'An error occurred while registering sessions!', e
      puts e.backtrace
    rescue IO::EAGAINWaitReadable
      err 'No sockets to register!' if RuneRb::GLOBAL[:RRB_DEBUG]
    end

    # Unregisters a socket from the selector and removes it's reference from the system client list.
    def unregister(session)
      @sessions.delete(session.socket)
      @selector.deregister(session.socket)
      log RuneRb::COL.green("De-registered socket for #{session.ip}")
    rescue StandardError => e
      err 'An error occurred while unregistering session!',e
      puts e.backtrace
    end

    # Processes active sessions and removes inactive sessions.
    def process_session(task = Async::Task.current, socket)
      task.async do |sub|
        @sessions[socket].update(task: sub)
        @world.login(@sessions[socket]) if @sessions[socket].status[:auth] == :PENDING_WORLD
        unregister(@sessions[socket]) unless @sessions[socket].status[:active]
      end
    rescue StandardError => e
      err 'An error occurred while processing session!', e
      puts e.backtrace
    end

    def parse_config(config)
      raise 'No RuneRb::Game::World::Instance provided to the Endpoint!' unless config[:world]

      @id = config[:id] || config[:endpoint_id] || Druuid.gen
      @world = config[:world]
      @host = config[:host] || RuneRb::GLOBAL[:RRB_HOST]
      @port = config[:port] || RuneRb::GLOBAL[:RRB_PORT]
    end
  end
end