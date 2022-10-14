# A collection of Map Constants
module RuneRb::Game::Map::Constants
  NONE = -1
  NORTH_WEST = 0

  NORTH = 1
  NORTH_EAST = 2

  WEST = 3
  EAST = 4

  SOUTH_WEST = 5
  SOUTH = 6
  SOUTH_EAST = 7

  DIRECTIONS = { NONE: NONE,
                 NORTH_WEST: NORTH_WEST,
                 NORTH: NORTH,
                 NORTH_EAST: NORTH_EAST,
                 WEST: WEST,
                 EAST: EAST,
                 SOUTH_WEST: SOUTH_WEST,
                 SOUTH: SOUTH,
                 SOUTH_EAST: SOUTH_EAST }.freeze

  NESW = [NORTH, EAST, SOUTH, WEST].freeze
  WNES = [WEST, NORTH, EAST, SOUTH].freeze
  WNES_DIAGONAL = [NORTH_WEST, NORTH_EAST, SOUTH_EAST, SOUTH_WEST].freeze

  DEFAULT_POSITION = [ENV['RRB_GAME_DEFAULT_X'].to_i || 3222, ENV['RRB_GAME_DEFAULT_Y'].to_i || 3222, ENV['RRB_GAME_DEFAULT_Z'].to_i || 0].freeze

  REGION_TILE_LENGTH = 8
  VIEWABLE_REGION_RADIUS = 3
  VIEWPORT_WIDTH = REGION_TILE_LENGTH * 13
  X_DELTAS = [-1, 0, 1, -1, 1, -1, 0, 1].freeze
  Y_DELTAS = [1, 1, 1, 0, 0, -1, -1, -1].freeze
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