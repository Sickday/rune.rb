module RuneRb::Entity
  class Context < RuneRb::Entity::Type
    include RuneRb::Types::Loggable
    include RuneRb::Network::FrameWriter


    def disconnect
      write_disconnect
      super
    end
    # Called when a new Context Entity is created.
    # @param client [RuneRb::Network::Client] the peer client to be associated with the entity.
    def initialize(client)
      super()
      @client = client
      @inventory = RuneRb::Entity::Inventory.new
      @tile = RuneRb::Game::Map::Tile.new(3222, 3222, 0)
      @update = true
      @region_changed = true # Region changed?
      @reset_movement = false
      #self[:equipment] = RuneRb::Entity::Equipment.new
    end

    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
    end
  end
end
