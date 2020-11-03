module RuneRb::Database
  class Location < Sequel::Model(PROFILES[:location])
    include RuneRb::Types::Loggable

    # A simple Tile object with x, y, and z coordinates.
    Tile = Struct.new(:x, :y, :z) do
      def inspect
        "[x: #{self.x}, y: #{self.y}, z: #{self.z}]"
      end
    end

    # @return [Tile] a tile with region coordinates for the location.
    def region
      Tile.new((self[:x] >> 3) - 6, (self[:y] >> 3) - 6, self[:z])
    end

    # @return [Tile] a tile with local coordinates for the location.
    def local
      Tile.new(self[:x] - 8 * ((self[:x] >> 3) - 6),
               self[:y] - 8 * ((self[:y] >> 3) - 6),
               self[:z])
    end

    # Translates the current point of the tile by the specified parameters
    # @param x_amount [Integer] the amount to translate on the x axis
    # @param y_amount [Integer] the amount to translate on the y axis
    # @param z_amount [Integer] the amount to translate on the z axis
    def translate(x_amount, y_amount, z_amount = 0)
      update(x: self[:x] + x_amount)
      update(y: self[:y] + y_amount)
      update(z: self[:z] + z_amount)
    end

    alias move translate

    def inspect
      log "BASE:\t#{@base.inspect}", "REGION:\t#{@region.inspect}", "LOCAL:\t#{@local.inspect}"
    end

    # Compares this tile to another tile.
    # @param other [Tile] the tile we're comparing to.
    def same?(other)
      self[:x] == other[:x] && self[:y] == other[:y] && self[:z] == other[:z]
    end

    alias == same?

    class << self
      # @param x [Integer] the tile's x position.
      # @param y [Integer] the tile's y position.
      # @param z [Integer] the tile's plane/height/z.
      # @return [Tile] the tile at the provided coordinates.
      def at(x, y, z = 0)
        Tile.new(x, y, z)
      end

      def direction_for(delta_x, delta_y)
        if delta_x.negative?
          if delta_y.negative?
            5
          elsif delta_y.positive?
            0
          else
            3
          end
        elsif delta_x.positve?
          if delta_y.negative?
            7
          elsif delta_y.positive?
            2
          else
            4
          end
        else
          if delta_y.negative
            6
          elsif delta_y.positive?
            1
          else
            -1
          end
        end
      end
    end
  end
end