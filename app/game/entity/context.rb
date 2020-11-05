module RuneRb::Entity
  class Context < RuneRb::Entity::Type
    include RuneRb::Types::Loggable

    attr :flags, :position, :region, :movement

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Network::Peer] the peer to be associated with the entity.
    def initialize(peer, profile)
      @session = peer
      @profile = profile
      @position = profile.location.position
      @inventory = RuneRb::Game::Inventory.new
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

    def update_region
      @region = @position
    end
  end
end
