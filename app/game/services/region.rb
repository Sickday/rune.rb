module RuneRb::Game::Services
  class RegionService
    attr :regions

    REGION_SIZE = 32

    # Called when a new RegionService is created
    def initialize(world)
      @regions = { active: [], inactive: [] }
      @world = world
    end

    def request(base_tile)

      @regions[:active] << RuneRb::Game::Map::Region.new(base_tile, @world)
    end

    def around(region)
      [].tap do |arr|
        arr << request(region.tile)
      end
    end

    def exists?(tile)
      @regions[:active].any? { |region| region.includes?(tile) }
    end

    # @return [Tile] the regional tile for the Tile instance data.
    def region_tile(tile)
      RuneRb::Game::Map::Tile.new(x: tile[:x] / 8 - 6,
                                  y: tile[:y] / 8 - 6,
                                  z: tile[:z])
    end
  end
end