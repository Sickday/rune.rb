module RuneRb::Net
  # Represents a host endpoint which accepts sockets and alerts them to populate their buffers via an internal nio selector
  class Endpoint
    include RuneRb::Internal::Log

    # @return [Hash] the information for this endpoint. Includes the Host and Port
    attr :info

    # @return [RuneRb::World::Instance] the World associated with the Endpoint
    attr :world

    # Called when a new Endpoint is created.
    # @param host [String] the host for the Endpoint.
    # @param port [Integer, String] the port for the Endpoint.
    # @param world [RuneRb::World::Instance] the world Instance paired with the Endpoint.
    def initialize(world, host = ENV['HOST'] || '0.0.0.0', port = ENV['PORT'] || 43_594)
      raise 'No RuneRb::World::Instance provided to the Endpoint!' unless world

      @world = world
      @info = { host: host, port: port }
      @sessions = []
      @selector = NIO::Selector.new
      @server = TCPServer.new(host, port)
      @selector.register(@server, :r).value = proc { accept_session }
      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Spawns a new process and executes the selection loop within that process. *
    def deploy
      # I'm unsure the limits of what can be called in Trap Context but we track uptime here and call exit.
      Signal.trap('INT') do
        puts RuneRb::COL.green("Up-time: #{RuneRb::COL.yellow.bold((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time).round(3))} Secs")
        exit
      end

      Parallel.in_processes(count: 1) do
        Concurrent::TimerTask.execute(execution_interval: 0.600) do
          return if @sessions.empty?

          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            @sessions.each do |session|
              session.pulse if session.status[:auth] == :LOGGED_IN
              @sessions.delete(session) unless session.status[:active]
            end
            log "Pulse completed in #{RuneRb::COL.yellow.bold((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(3))} seconds" if RuneRb::DEBUG
          rescue StandardError => e
            err 'An error occurred during a pulse!', e
            puts e.backtrace
          end
        end

        log RuneRb::COL.green("Endpoint deployed: #{RuneRb::COL.yellow.bold("#{@info[:host]}:#{@info[:port]}")}")
        loop { @selector.select { |monitor| monitor.value.call } }
      end
    end

    # De-registers a socket from the selector and removes it's reference from the internal client list.
    def deregister(session, socket)
      @selector.deregister(socket)
      @sessions.delete(session)
      log RuneRb::COL.green("De-registered socket for #{RuneRb::COL.cyan(session.ip)}")
    rescue StandardError => e
      err 'An error occurred while deregistering session!', e
      puts e.backtrace
    end

    private

    # Accepts a new socket connection via TCPServer#accept_nonblock and registers it with the Endpoint#clients hash. Sockets that are accepted are registered with the Endpoint#selector with an :r (readable) interest. The returned monitor object is passed a proc to execute `Endpoint#touch_clients` which is called when an interest is raised for the corresponding socket (it becomes readable/writable).
    def accept_session
      socket = @server.accept_nonblock
      host = socket.peeraddr[-1]
      @sessions << RuneRb::Net::Session.new(socket, self)
      @selector.register(socket, :r).value = proc { update_sessions }
      log RuneRb::COL.green("Registered new socket for #{RuneRb::COL.cyan(host)}")
    end

    # Attempts to update peer streams via Peer#receive_data
    def update_sessions
      @sessions.each do |session|
        session.status[:active] ? session.receive_data : deregister(session, session.socket)
      end
    end
  end
end