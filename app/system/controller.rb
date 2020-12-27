module RuneRb::System
  class Controller < Async::Container::Controller
    include Log

    def initialize(config = {})
      # parse_config(config)
      @endpoints = {}
      @worlds = {}
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
    end

    # Deploys an object depending on the passed type and configuration.
    # @param type [Symbol] the type of object to deploy
    # @param configuration [Hash] configuration for the object
    def deploy(type, configuration)
      case type
      when :endpoint
        # return unless validate_config(configuration, :endpoint)

        ep = RuneRb::Network::Endpoint.new(configuration)
        @endpoints[ep.id] = ep
        ep
      when :world
        # return unless validate_config(configuration, :world)

        world = RuneRb::Game::World::Instance.new(configuration)
        @worlds[world.id] = world
        world
      else raise 'Unrecognized object type requested for deployment!'
      end
    rescue StandardError => e
      err 'An error occurred processing deployment!', e
      puts e.backtrace
    end

    def setup(container)
      @process = container
      log! 'Spawned Container object!'

      @process.run(name: class_name.to_s, count: 1, restart: true) do |process|
        Async do |task|
          # Process deployment for endpoints
          @endpoints.each_value { |endpoint| task.async { endpoint.deploy(task: task) } }

          # Process deployment for world instances
          @worlds.each_value { |world| task.async { world.deploy(task: task) } }

          process.ready!
        end.wait
      end
      @process.wait if @process.running?
    rescue StandardError => e
      err! 'A fatal error occurred during container deployment!', e
      puts e.backtrace
    ensure
      @process.stop
    end

    def stop(graceful = true)
      @worlds.each_value { |world| Async { world.shutdown(graceful: graceful) } }
      @endpoints.each_value { |endpoint| Async { endpoint.shutdown(graceful: graceful) } }
    rescue StandardError => e
      err 'An error occurred preventing a graceful shutdown!', e
      puts e.backtrace
    ensure
      @process&.stop
    end

    private

    # Attempts to validate a configuration hash according to the type of object it was meant to deploy
    # @param configuration [Hash] the config to validate
    # @param type [Symbol] the type of configuration
    def validate_config(configuration, type)
      raise 'Invalid configuration provided!' unless configuration

      case type
      when :world
        raise 'No Endpoint ID provided!' unless configuration[:endpoint] || configuration[:endpoint_id]
        raise 'Invalid Endpoint ID' unless configuration[:endpoint].is_a?(Integer) || configuration[:endpoint].is_a?(RuneRb::Network::Endpoint) || configuration[:endpoint_id].is_a?(Integer)
        raise 'Binding Endpoint for world could not be located!' unless @endpoints.values.any? do |ep|
          (ep.id == configuration[:endpoint_id] || configuration[:endpoint]) || ep == configuration[:endpoint]
        end
      when :endpoint
        raise 'No World ID provided!' unless configuration[:world] || configuration[:world_id]
        raise 'Invalid World ID' unless configuration[:world].is_a?(Integer) || configuration[:world].is_a?(RuneRb::Game::World::Instance) || configuration[:world_id].is_a?(Integer)
        raise 'Binding World for endpoint could not be located!' unless @worlds.values.any? do |w|
          (w.id == configuration[:world] || configuration[:world_id]) || w == configuration[:world]
        end
      end
      true
    end
  end
end