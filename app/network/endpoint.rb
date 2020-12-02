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
      @peers = []
      @pulse = init_pulse
      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Initializes the pulse task
    def init_pulse
      Concurrent::TimerTask.new(execution_interval: 0.600) do
        return if @peers.empty?

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          @peers.each do |peer|
            peer.pulse if peer.status[:auth] == :LOGGED_IN
            @peers.delete(peer) unless peer.status[:active]
          end
          log "Pulse completed in #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(3)} seconds" if RuneRb::DEBUG
        rescue StandardError => e
          err 'An error occurred during a pulse!'
          puts e
          puts e.backtrace
        end
      end
    rescue StandardError => e
      err! 'An error occurred while initializing pulse task!'
      puts e
      puts e.backtrace
    end

    # Spawns a new process and launches a TCPServer object to listen on Endpoint#info[:host] : Endpoint#info[:port]  *
    def deploy
      # I'm unsure the limits of what can be called in Trap Context but we track uptime here and call exit.
      Signal.trap('INT') do
        puts RuneRb::COL.green("Up-time: #{RuneRb::COL.yellow.bold((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time).round(3))} Sec")
        exit
      end

      # Launch the actual server in a separate process as to [hopefully] mitigate any load that might fall on threads it would use in this process.
      Parallel.in_processes(count: 1) do
        # Run EventMachine reactor here
        EventMachine.run do
          # Launch the EventMachine server.
          EventMachine.start_server(@info[:host], @info[:port], RuneRb::Net::Peer) do |peer|
            peer.attach_to(self)
            @peers << peer
          end
          log RuneRb::COL.green("Endpoint deployed: #{RuneRb::COL.yellow.bold("#{@info[:host]}:#{@info[:port]}")}")
          @pulse.execute
        end
      end
    end
  end
end