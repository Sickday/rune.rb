# A module providing virtual positioning and game mapping
module RuneRb::Map
  # An object holding the top left X and Y coordinates of a region
  class Regional
    include RuneRb::Types::Loggable
    # The x and y coordinates for the regional. (comparable to Position#top_left_region_x, or Position#top_left_region_y)
    attr :x, :y

    # Called when a new Regional is created
    # @param x [Integer] the x coordinate
    # @param y [Integer] the y coordinate
    def initialize(x, y)
      @x = x
      @y = y
    end

    # The absolute X coordinate of this Region (comparable to Position#[:x])
    def absolute_x
      RuneRb::Map::REGION_TILE_LENGTH * (@x + 6)
    end

    # The absolute Y coordinate of this Region (comparable to Position#[:y])
    def absolute_y
      RuneRb::Map::REGION_TILE_LENGTH * (@y + 6)
    end

    def inspect
      "[x:#{@x}, y:#{@y}]"
    end

    # Checks if the Regional holds the same value as another
    def eql?(other)
      false unless other.is_a? Regional
      log "OtherX: #{other.x}, OtherY: #{other.y}", "ContextX: #{@x}, ContextY: #{@y}"
      @x == other.x && @y == other.y
    end

    # Checks if the Regional would include the given Position
    # @param position [RuneRb::Map::Position] the Position.
    def includes?(position)
      other = Regional.from_position(position)
      true if other.eql?(self)
    end

    class << self
      # @param other [Position] the Position to get the regional for
      # @return [Regional] regional Position for the given Position
      def from_position(other)
        Regional.new(other.top_left_region_x, other.central_region_y)
      end
    end
  end
end