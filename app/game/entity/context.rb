module RuneRb::Entity
  class Context < RuneRb::Entity::Type
    include RuneRb::Types::Loggable

    attr :updates, :location

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Network::Peer] the peer to be associated with the entity.
    def initialize(peer, profile)
      super({ x: 2606, y: 3095, z: 0 })

      @session = peer
      @profile = profile
      @location = profile.location
      @inventory = RuneRb::Entity::Inventory.new
      @updates = {}
      log profile.inspect
      reset_updates
    end

    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
    end

    # Reset the context entity's updates.
    def reset_updates
      @updates[:state?] = true
      @updates[:region?] = true
      @updates[:reset_move?] = true
      @updates[:required?] = true
      @updates[:placement?] = true
    end
  end
end
