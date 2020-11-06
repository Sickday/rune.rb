module RuneRb::Entity
  class Context < RuneRb::Entity::Type
    include RuneRb::Types::Loggable

    attr :position, :region, :movement, :profile, :inventory

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Network::Peer] the peer to be associated with the entity.
    def initialize(peer, profile)
      super()
      @session = peer
      @profile = profile
      @position = profile.location.position

      load_inventory

      @updates = {}
      @movement = { walk: -1,
                    run: -1,
                    teleport: { to: @position },
                    handler: RuneRb::Game::Map::Movement.new(self) }
      reset_updates
      update_region
    end

    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
    end

    # Reset the context entity's updates.
    def reset_updates
      @flags[:state?] = true
      @flags[:region?] = true
      @flags[:reset_move?] = true
    end

    # @param direction [Integer] the direction the player is facing
    def facing(direction)
      @flags[:facing] = direction
    end

    def load_inventory
      if !@profile[:inventory].nil?
        @inventory = RuneRb::Game::Inventory.restore(self)
        log(RuneRb::COL.green("Restored Inventory for #{@profile[:name]}"), @inventory.inspect) if RuneRb::DEBUG
      else
        @inventory = RuneRb::Game::Inventory.new
        log(RuneRb::COL.magenta("New Inventory set for #{@profile[:name]}")) if RuneRb::DEBUG
      end
      @session.write_inventory(28, @inventory.data)
    end

    def logout
      RuneRb::Game::Inventory.dump(self)
    end

    def appearance
      @profile.appearance
    end

    def update_region
      @region = @position
    end
  end
end
