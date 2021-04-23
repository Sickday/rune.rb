module RuneRb::Network::RS317::SwitchItemMessage
  include RuneRb::System::Log

  # Parses the SwitchItemMessage
  # @param context [RuneRb::Game::Entity::Context] the context to parse for
  def parse(context)
    interface = read_short(false, :ADD, :LITTLE)
    _insert = read_byte(false, :NEGATE).positive? # This will matter when bank is implemented. TODO: impl bank
    old_slot = read_short(false, :ADD, :LITTLE)
    new_slot = read_short(false, :STD, :LITTLE)

    case interface
    when 3214
      if old_slot >= 0 &&
        new_slot >= 0 &&
        old_slot <= context.inventory[:container].limit &&
        new_slot <= context.inventory[:container].limit
        context.inventory[:container].swap(old_slot, new_slot)
        context.update(:inventory)
      end
      log "Got Inventory SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{_insert} || [interface]: #{interface}"
    when 1688
      log "Got Equipment SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{_insert} || [interface]: #{interface}"
    else
      err "Unrecognized SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{_insert} || [interface]: #{interface}"
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