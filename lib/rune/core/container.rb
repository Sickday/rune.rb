module RuneRb
  class Container

    def initialize
      @components = {}
    end

    def run
      %i[server gateway world].each {|component| component.process }
    end

    def deploy(type = :all)
      case type
      when :all
        %i[gateway world server].each do |component|
          @components[component] = send("deploy_#{component}".to_sym)
        end
      when :gateway then deploy_gateway
      when :world then deploy_world
      when :server then deploy_server
      else raise ArgumentError, "Unknown component type to deploy, #{type}!"
      end
    end

    def close(type = :all)
      case type
      when :all
        %i[gateway world server].each { |component| send("close_#{component}".to_sym) }
      when :gateway then close_gateway
      when :world then close_world
      when :server then close_server
      else raise ArgumentError, "Unknown component type to close, #{type}!"
      end
    end

    private

    def close_world
      @world.shutdown
    end

    def close_server
      @server.shutdown
    end

    def close_gateway
      @gateway.shutdown
    end

    def deploy_gateway
      @components[:gateway] = RuneRb::Network::Gateway.new
    end

    def deploy_world
      # @components[:world] = RuneRb::Game::World.new
    end

    def deploy_server
      @components[:server] = RuneRb::Network::Server.new
    end
  end
end
