module RuneRb::Game::Map
  # An object holding the top left X and Y coordinates of a region
  class Regional
    include RuneRb::Utils::Logging
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
      RuneRb::Game::Map::REGION_TILE_LENGTH * (@coordinates[:x] + 6)
    end

    # The absolute Y coordinate of this Region (comparable to Position#[:y])
    def absolute_y
      RuneRb::Game::Map::REGION_TILE_LENGTH * (@coordinates[:y] + 6)
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
    # @param position [RuneRb::Game::Map::Position] the Position.
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

# Copyright (c) 2021, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.