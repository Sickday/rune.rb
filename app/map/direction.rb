module RuneRb::Map
  # An object providing Directional functions to Map positions and coordinates.
  class Direction
    class << self
      include RuneRb::Types::Loggable
      include RuneRb::Map::Constants

      # The Direction between two Positions
      # @param first [Position] the first Position
      # @param second [Position] the second Position
      def between(first, second)
        Direction.from_delta(((second[:y] - first[:y]) <=> 0),
                             ((second[:x] - first[:x]) <=> 0))
      end

      # Returns a direction from deltas between x and y coordinates
      # @param delta_x [Integer] the delta between 2 x coordinates
      # @param delta_y [Integer] the delta between 2 y coordinates
      def from_delta(delta_y, delta_x)
        case delta_y
        when 1
          case delta_x
          when 1 then NORTH_EAST
          when 0 then NORTH
          when -1 then NORTH_WEST
          end
        when -1
          case delta_x
          when 1 then SOUTH_EAST
          when 0 then SOUTH
          when -1 then SOUTH_WEST
          end
        when 0
          case delta_x
          when 1 then EAST
          when 0 then NONE
          when -1 then WEST
          end
        end
      end

      # The 2 directions that make up a specific direction.
      # @param direction [Symbol] the direction.
      def diagonal_directions(direction)
        case direction
        when :NORTH_EAST then [NORTH, EAST]
        when :NORTH_WEST then [NORTH, WEST]
        when :SOUTH_EAST then [SOUTH, EAST]
        when :SOUTH_WEST then [SOUTH, WEST]
        else "Unrecognized direction #{direction}!"
        end
      end

      # Is the supplied direction diagonal?
      # @param direction [Symbol] the direction.
      def diagonal?(direction)
        %i[SOUTH_WEST SOUTH_EAST NORTH_WEST NORTH_EAST].include?(direction)
      end

      # Gets the client's orientation for the direction
      # @param direction [Symbol] the direction.
      def orientation_for(direction)
        case direction
        when :WEST, :NORTH_WEST then 0
        when :NORTH, :NORTH_EAST then 1
        when :EAST, :SOUTH_EAST then 2
        when :SOUTH, :SOUTH_WEST then 3
        else 'Only a valid direction can have orientation.'
        end
      end
    end
  end
end
