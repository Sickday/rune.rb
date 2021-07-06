module RuneRb::Database::Player
  # The `player_stats` table contains data related to an individual player's skills/stats. This object models a single row of that table.
  #
  # Models a row of the `player_stats` table
  class Stats < Sequel::Model(RuneRb::GLOBAL[:PLAYER_STATS])

    # Adds a specified amount to the corresponding <_experience> row of the passed skill
    # @param skill [Symbol] the skill to add experience to
    # @param amount [Integer] the amount of experience to add
    def add_experience(skill, amount)
      eventual = self[SKILLS[skill].last] + amount
      update_exp(skill, eventual)
    end

    # Updates all skills with a level of 99 and an experience of 13,034,430
    def max
      SKILLS.each_value do |columns|
        update(columns.first => 99)
        update(columns.last => 13_034_430)
      end
    end

    class << self

      # Calculates the appropriate level for the amount of passed experience
      # @param xp [Integer] the experience to fetch the level for.
      # @return [Integer] the skill level for the given amount of experience
      def level_for_experience(xp)
        if xp > 13_034_430
          99
        else
          points = 0
          lvl = (1..99).detect do |level|
            points += (level + 300.0 * (2**(level / 7.0))).floor
            (points / 4).floor >= xp
          end
          lvl >= 99 ? 99 : lvl
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