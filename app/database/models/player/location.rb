module RuneRb::Database
  # Information related to the location of a player in the virtual game world
  #
  # Models a row from the `player_locations` table
  class PlayerLocation < Sequel::Model(RuneRb::GLOBAL[:PLAYER_LOCATIONS])
    # Constructs a <RuneRb::Game::Map::Position> from the location.
    # @return [RuneRb::Game::Map::Position]
    def to_position
      RuneRb::Game::Map::Position.new(self[:x], self[:y], self[:z])
    end

    # Updates the <:x, :y, :z> values to that of the passed position object.
    # @param position [RuneRb::Game::Map::Position] the position to update the location coordinates with.
    def set(position)
      update(prev_x: self[:x],
             prev_y: self[:y],
             prev_z: self[:z],
             x: position[:x] || RuneRb::GLOBAL[:DEFAULT_MOB_X] || 3222,
             y: position[:y] || RuneRb::GLOBAL[:DEFAULT_MOB_Y] || 3222,
             z: position[:z] || RuneRb::GLOBAL[:DEFAULT_MOB_Z] || 0)
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