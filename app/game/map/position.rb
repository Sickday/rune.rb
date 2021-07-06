module RuneRb::Game::Map
  # A Position object provides a base tile as well as region and local tiles.
  class Position
    # @return [Hash] a hash wrapping the Position's absolute X and absolute Y coordinates.
    attr :coordinates

    # Called when a new Position is created.
    # @param abs_x [Integer] the x coordinate.
    # @param abs_y [Integer] the y coordinate.
    # @param z [Integer] the z coordinate.
    def initialize(abs_x, abs_y, z = 0)
      @coordinates = { x: abs_x, y: abs_y, z: z }
    end

    # Compares this position to another
    # @param other [Position] the other Position
    def eql?(other)
      return false unless other.is_a? Position

      @coordinates[:x] == other[:x] && @coordinates[:y] == other[:y] && @coordinates[:z] == other[:z]
    end

    # Updates the Position instance to that of other
    # @param other [Position] the other Position
    def to(other)
      @coordinates[:x] = other[:x]
      @coordinates[:y] = other[:y]
      @coordinates[:z] = other[:z]
    end

    # Moves the position by specified amounts
    def move(x_amount, y_amount, z_amount = 0)
      @coordinates[:x] += x_amount
      @coordinates[:y] += y_amount
      @coordinates[:z] += z_amount
      self
    end

    # The X coordinate of the central region for the Position.
    # @return [Integer] The x coordinate for the central region for the Position
    def central_region_x
      @coordinates[:x] / 8
    end

    # The Y coordinate of the central region for the Position.
    # @return [Integer] The y coordinate of the central region for the position.
    def central_region_y
      @coordinates[:y] / 8
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
      @coordinates[:x] - base.top_left_region_x * 8
    end

    # The local y coordinate inside the region of base
    # @param base [Position] the base position
    # @return [Integer] the local y coordinate relative to the base parameter
    def local_y(base = self)
      @coordinates[:y] - base.top_left_region_y * 8
    end

    # Gets regional coordinates for a Position
    # @param position [Position] the Position to get regional coordinates for.
    def regional(position = self)
      Regional.from_position(position)
    end

    # Checks if other is in view of the Position
    # @param other [Position] the position that may or may not be in view
    # @return [Boolean] is the distance between the Position and other greater less than 16
    def in_view?(other)
      delta_x = @coordinates[:x] - other[:x]
      delta_y = @coordinates[:y] - other[:y]
      delta_x <= 14 && delta_x >= -15 && delta_y <= 14 && delta_y >= -15
    end

    # Shorthand coordinate retrieval
    # @param coordinate [Symbol] the coordinate to retrieve (:x, :y, :z)
    def [](coordinate)
      @coordinates[coordinate]
    end

    # Shorthand coordinate assignment
    # @param coordinate [Symbol] the coordinate to assign (:x, :y, :z)
    # @param value [Integer] the value to assign the coordinate to.
    def []=(coordinate, value)
      @coordinates[coordinate] = value
    end

    # The longest horizontal or vertical delta between the positions.
    # @return [Integer] the longest horizontal or vertical delta between the position.
    # @param other [Position] the other position
    def longest_delta(other)
      delta_x = @coordinates[:x] - other[:x]
      delta_y = @coordinates[:y] - other[:y]
      [delta_x, delta_y].max || delta_x || 0
    end

    # The distance between the position and another
    # @param other [Position] the other position
    def distance_to(other)
      delta_x = @coordinates[:x] - other[:x]
      delta_y = @coordinates[:y] - other[:y]
      Math.sqrt(delta_x * delta_x + delta_y * delta_y).ceil
    end

    def inspect
      "[AbsX: #{@coordinates[:x]}, AbsY: #{@coordinates[:y]}, AbsZ: #{@coordinates[:z]}] || [LocX: #{local_x}, LocY: #{local_y}] || [RegX: #{central_region_x}, RegY: #{central_region_y}]"
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