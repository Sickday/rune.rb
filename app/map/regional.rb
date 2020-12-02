# A module providing virtual positioning and game mapping
module RuneRb::Map
  # An object holding the top left X and Y coordinates of a region
  class Regional
    include RuneRb::Internal::Log
    # The x and y coordinates for the regional. (comparable to Position#top_left_region_x, or Position#top_left_region_y)
    attr :coordinates

    # Called when a new Regional is created
    # @param regional_x [Integer] the regional_x coordinate
    # @param regional_y [Integer] the regional_y coordinate
    def initialize(regional_x, regional_y)
      @coordinates = { x: regional_x, y: regional_y }
    end

    # The absolute X coordinate of this Region (comparable to Position#[:x])
    def absolute_x
      RuneRb::Map::REGION_TILE_LENGTH * (@coordinates[:x] + 6)
    end

    # The absolute Y coordinate of this Region (comparable to Position#[:y])
    def absolute_y
      RuneRb::Map::REGION_TILE_LENGTH * (@coordinates[:y] + 6)
    end

    # Shorthand coordinate retrieval.
    # @param coord [Symbol] the coordinate to retrieve.
    def [](coord)
      @coordinates[coord]
    end

    # Shorthand coordinate assignment
    # @param coord [Symbol] the coordinate to assign.
    # @param value [Integer] the value to assign the coordinate to.
    def []=(coord, value)
      @coordinates[coord] = value
    end

    # Checks if the Regional holds the same value as another
    def eql?(other)
      false unless other.is_a? Regional
      log "OtherX: #{other[:x]}, OtherY: #{other[:y]}", "ContextX: #{@coordinates[:x]}, ContextY: #{@coordinates[:y]}"
      @coordinates[:x] == other[:x] && @coordinates[:y] == other[:y]
    end

    # Checks if the Regional would include the given Position
    # @param position [RuneRb::Map::Position] the Position.
    def includes?(position)
      Regional.from_position(position).eql?(self)
    end

    def inspect
      "CENTRAL: [CentralX:#{@coordinates[:x]}, CentralY:#{@coordinates[:y]}] || ABSOLUTE: [AbsoluteX:#{absolute_x}, AbsoluteY:#{absolute_y}]"
    end

    class << self
      # @param other [Position] the Position to get the regional for
      # @return [Regional] regional Position for the given Position
      def from_position(other)
        Regional.new(other.central_region_x, other.central_region_y)
      end
    end
  end
end