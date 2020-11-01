module RuneRb::Game::Map
  class Tile
    include RuneRb::Types::Serializable

    def initialize(x, y, z = 0)
      self[:x] = x
      self[:y] = y
      self[:z] = z
    end

    def self.direction_for(delta_x, delta_y)
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

    # Translates the current point of the tile by the specified parameters
    # @param x_amount [Integer] the amount to translate on the x axis
    # @param y_amount [Integer] the amount to translate on the y axis
    # @param z_amount [Integer] the amount to translate on the z axis
    def translate(x_amount, y_amount, z_amount = 0)
      self[:x] += x_amount
      self[:y] += y_amount
      self[:z] += z_amount
    end

    alias move translate

    # @return [String] String representation of this tile.
    def inspect
      "[#{self[:x]},#{self[:y]},#{self[:z]}]"
    end

    # Compares this tile to another tile.
    # @param other [Tile] the tile we're comparing to.
    def same?(other)
      self[:x] == other[:x] && self[:y] == other[:y] && self[:z] == other[:z]
    end

    alias == same?

    ## TODO: impl ;)
    def path_to(tile); end
  end
end