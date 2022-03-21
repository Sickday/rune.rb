module RuneRb::Game::Map
  # An object providing Directional functions to map positions and coordinates.
  class Direction
    class << self
      include RuneRb::Utils::Logging
      include RuneRb::Game::Map::Constants

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