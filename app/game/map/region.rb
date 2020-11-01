module RuneRb::Game::Map
  class Region

    attr :current_tile, :regional_tile, :local_tile

    # Called when a new Region is created
    # @param x [Integer] the x coordinate position
    # @param y [Integer] the y coordinate position
    # @param z [Integer] the z coordinate position
    def initialize(x, y, z)
      at(x, y, z)
      update
    end

    # @return [Region] creates a region around a tile.
    def from(tile)
      Map::Region.new(tile[:x], tile[:y], tile[:z])
    end


    def self.regional_tile(base_tile)
      Map::Tile.new((base_tile[:x] >> 3) - 6,
                    (base_tile[:y] >> 3) - 6,
                    base_tile[:z])
    end

    def self.local_tile(base_tile)
      reg = regional_tile(base_tile)
      Map::Tile.new(base_tile[:x] - 8 * reg[:x],
                    base_tile[:x] - 8 * reg[:x],
                    base_tile[:z])
    end

    # Updates the tiles current point to a new one specified by the parameters.
    # @param x [Integer] the x position
    # @param y [Integer] the y position
    # @param z [Integer] the z position
    def self.at(x, y, z = 0)
      @current_tile = Map::Tile.new(x, y, z)
    end

    # Updates the internal tiles for the region.
    def update
      @regional_tile = regional_tile(@current_tile)
      @local_tile = local_tile(@current_tile)
    end

    def contains?(tile)

    end
  end
end