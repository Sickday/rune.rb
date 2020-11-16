module RuneRb::Map
  # A Position object provides a base tile as well as region and local tiles.
  class Position
    # @return [Struct] a Data object wrapping the positions coordinates.
    attr :data

    # A object wrapping the Position's coordinates.
    Data = Struct.new(:x, :y, :z) do

      # Transforms the coordinates by the specified amounts.
      # @param amount_x [Integer] the amount to transform the x coordinate.
      # @param amount_y [Integer] the amount to transform the y coordinate.
      # @param amount_z [Integer] the amount to transform the z coordinate.
      def transform(amount_x, amount_y, amount_z)
        self.x += amount_x
        self.y += amount_y
        self.z += amount_z
      end
    end

    # Called when a new Position is created.
    # @param x [Integer] the x coordinate.
    # @param y [Integer] the y coordinate.
    # @param z [Integer] the z coordinate.
    def initialize(x, y, z = 0)
      @data = Data.new(x, y, z)
    end

    # Compares this position to another
    # @param other [Position] the other Position
    def eql?(other)
      return false unless other.is_a? Position

      @data[:x] == other[:x] && @y == other[:y] && @data[:z] == other[:z]
    end

    # Updates the Position instance to that of other
    # @param other [Position] the other Position
    def to(other)
      @data[:x] = other[:x]
      @data[:y] = other[:y]
      @data[:z] = other[:z]
    end

    # Moves the position by specified amounts
    def move(x_amount, y_amount, z_amount = 0)
      @data.transform(x_amount, y_amount, z_amount)
    end

    # Gets regional coordinates for a Position
    # @param position [Position] the Position to get regional coordinates for.
    def regional_for(position = self)
      Regional.from_position(position)
    end

    # The X coordinate of the central region for the Position.
    # @return [Integer] The x coordinate for the central region for the Position
    def central_region_x
      @data[:x] >> 3
    end

    # The Y coordinate of the central region for the Position.
    # @return [Integer] The y coordinate of the central region for the position.
    def central_region_y
      @data[:y] >> 3
    end

    # The X coordinate of the region this position is in.
    # @return [Integer] The X coordinate of the region this position is in.
    def top_left_region_x
      central_region_x - 6
    end

    # The Y coordinate the region this position is in.
    # @return [Integer] The Y coordinate of the region this position is in.
    def top_left_region_y
      central_region_y - 6
    end

    # The local x coordinate inside the region of base
    # @param base [Position] the base position
    # @return [Integer] the local x coordinate relative to the base parameter
    def local_x(base = self)
      @data[:x] - base.top_left_region_x * 8
    end

    # The local y coordinate inside the region of base
    # @param base [Position] the base position
    # @return [Integer] the local y coordinate relative to the base parameter
    def local_y(base = self)
      @data[:y] - base.top_left_region_y * 8
    end

    # Checks if other is in view of the Position
    # @param other [Position] the position that may or may not be in view
    # @return [Boolean] is the distance between the Position and other greater less than 16
    def in_view?(other)
      delta_x = @data[:x] - other[:x]
      delta_y = @data[:y] - other[:y]
      delta_x <= 14 && delta_x >= -15 && delta_y <= 14 && delta_y >= -15
    end

    # Shorthand coordinate retrieval
    # @param coordinate [Symbol] the coordinate to retrieve (:x, :y, :z)
    def [](coordinate)
      @data[coordinate]
    end

    # Shorthand coordinate assignment
    # @param coordinate [Symbol] the coordinate to assign (:x, :y, :z)
    # @param value [Integer] the value to assign the coordinate to.
    def []=(coordinate, value)
      @data[coordinate] = value
    end

    # The longest horizontal or vertical delta between the positions.
    # @return [Integer] the longest horizontal or vertical delta between the position.
    # @param other [Position] the other position
    def longest_delta(other)
      delta_x = @data[:x] - other[:x]
      delta_y = @data[:y] - other[:y]
      [delta_x, delta_y].max || delta_x || 0
    end

    # The distance between the position and another
    # @param other [Position] the other position
    def distance_to(other)
      delta_x = @data[:x] - other[:x]
      delta_y = @data[:y] - other[:y]
      Math.sqrt(delta_x * delta_x + delta_y * delta_y).ceil
    end

    class << self

      # A position at the given coordinates.
      # @param x [Integer] the x coordinate.
      # @param y [Integer] the y coordinate.
      # @param z [Integer] the z coordinate.
      def at(x, y, z = 0)
        Position.new(x, y, z)
      end

      # Create a Position with delta amounts between the provided positions.
      # @param first [Position] the first position
      # @param second [Position] the second position
      # @return [Position] a Position containing the delta coordinates for the provided parameters.
      def delta(first, second)
        Position.new(first[:x] - second[:x],
                     first[:y] - second[:y],
                     first[:z] - second[:z])
      end

      # The direction for the given deltas.
      # @param delta_y [Integer] the y delta
      # @param delta_x [Integer] the x delta
      # @return [Integer] the Direction for the given deltas
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
          if delta_y.negative?
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