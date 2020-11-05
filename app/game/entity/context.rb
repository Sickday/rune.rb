module RuneRb::Entity
  class Context < RuneRb::Entity::Type
    include RuneRb::Types::Loggable

    attr :flags, :position, :region, :movement, :profile, :inventory

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Network::Peer] the peer to be associated with the entity.
    def initialize(peer, profile)
      @session = peer
      @profile = profile
      @position = profile.location.position

      load_inventory

      @updates = {}
      @flags = {}
      @movement = { first: -1,
                    second: -1,
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
      @flags[:state?] = false
      @flags[:region?] = true
      @flags[:reset_move?] = true
      @flags[:required?] = true
      @flags[:placement?] = true
      @flags[:moved?] = false
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
      @inventory.add(RuneRb::Game::ItemStack.new(4151))
      @inventory.add(RuneRb::Game::ItemStack.new(1049))
      @session.write_inventory(28, @inventory.data)
    end

    def logout
      RuneRb::Game::Inventory.dump(self)
    end

    def update_region
      @region = @position
    end
  end
end
