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

module RuneRb::Database
  # Information related to the appearance of a player in the virtual game world
  #
  # Models a row of the `player_appearance` table
  class PlayerAppearance < Sequel::Model(RuneRb::GLOBAL[:PLAYER_APPEARANCES])

    # Updates the `mob_id` column to the specified value.
    #
    # During the next ContextSynchronizationMessage this value is observed and applied to the ContextStateBlock which will ensure the appropriate mask is applied.
    # @param id [Integer] the id of the mob to appear as.
    def to_mob(id)
      update(mob_id: id)
    end

    # Resets the `mob_id` column to -1.
    #
    # During the next ContextSynchronizationMessage this value is observed and the player's actual appearance is sent.
    def from_mob
      update(mob_id: -1)
    end

    # Updates the `head_icon` column to the specified value
    #
    # During the next ContextSynchronizationMessage this value is observed and applied to the ContextStateBlock which will ensure the proper value is sent for the head_icon
    # @param id [Integer] the id of the head_icon to send.
    def to_head(id)
      update(head_icon: id)
    end
  end
end