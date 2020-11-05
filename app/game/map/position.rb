module RuneRb::Game::Map
  # A Position object provides a base tile as well as region and local tiles.
  class Position
    attr :x, :y, :z

    def initialize(x, y, z = 0)
      @x = x
      @y = y
      @z = z
    end

    # Compares this position to another
    def eql?(other)
      return false unless other.is_a? Position

      @x == other.x && @y == other.y && z == other.z
    end

    # Updates the Position instance to that of other
    def at(other)
      @x = other.x
      @y = other.y
      @z = other.z
    end

    # Moves the position by specified amounts
    def move(x_amount, y_amount, z_amount = 0)
      @x += x_amount
      @y += y_amount
      @z += z_amount
    end

    def region_x
      (@x >> 3) - 6
    end

    def region_y
      (@y >> 3) - 6
    end

    # @param base [Position] the base position
    # @return [Integer] the local x coordinate relative to the base parameter
    def local_x(base)
      @x - 8 * base.region_x
    end

    # @param base [Position] the base position
    # @return [Integer] the local y coordinate relative to the base parameter
    def local_y(base)
      @y - 8 * base.region_y
    end

    def in_view?(other)
      delta = Position.delta(self, other)
      delta.x <= 14 && delta.x >= -15 && delta.y <= 14 && delta.y >= -15
    end

    class << self
      def delta(first, second)
        Position.new(first.x - second.x,
                     first.y - second.y,
                     first.z - second.z)
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
        elsif delta_x.positive?
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