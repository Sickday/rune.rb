# Copyright (c) 2020, Patrick W.
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

module RuneRb::Game::Entity::Commands

  # Bans a profile from the network.
  class Ban < RuneRb::Game::Entity::Command
    def execute
      return unless @assets[:command][0].size > 0

      begin
        # First we update the banned status for the user
        RuneRb::Database::PlayerProfile[@assets[:command][0].downcase].update(banned: true)
        @assets[:context].session.write_message(:sys_message, message: "The player, #{@assets[:command][0]}, has been banned.")
      rescue StandardError => e
        err "An error occurred retrieving profile for: #{@assets[:command][0]}!", e
        puts e.backtrace
        return
      end

      # Next, we log the player out if they're connected to the same world instance.
      target = @assets[:context].world.request(:context, name: @assets[:command][0])
      if target
        @assets[:context].world.release(target)
      else
        @assets[:context].session.write_message(:sys_message, message: "Could not locate #{@assets[:command][0]} in any existing world instances.")
      end
    end
  end
end