module RuneRb::Game::Entity::Commands

  # A Command to spawn items for the player.
  class Item < RuneRb::Game::Entity::Command

    def execute
      unless @assets[:command].size >= 2
        @assets[:context].session.write_message(:SystemTextMessage, message: "Not enough parameters for this command! Required: 2 or more, Provided: #{@assets[:command].size}")
        return
      end
      stack = RuneRb::Game::Item::Stack.new(@assets[:command][0].to_i)
      if stack.definition.can_stack
        stack.size = @assets[:command][1].to_i
        @assets[:context].add_item(stack)
        log COLORS.green("Added item #{stack.definition.name} x #{stack.size}") if RuneRb::GLOBAL[:ENV].debug
      else
        @assets[:command][1].to_i.times do
          @assets[:context].add_item(stack)
          log COLORS.green("Added item #{stack.definition.name} x #{stack.size}") if RuneRb::GLOBAL[:ENV].debug
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