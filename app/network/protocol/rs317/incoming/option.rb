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

module RuneRb::Network::RS317::OptionClickMessage
  include RuneRb::System::Log

  # Parses the OptionClickMessage
  # @param context [RuneRb::Game::Entity::Context] the context to parse for
  def parse(context)
    case @header[:op_code]
    when 122 # First
      interface = read_short(true, :ADD, :LITTLE)
      slot = read_short(false, :ADD)
      item_id = read_short(true, :STD, :LITTLE)
    when 41 # Second
      item_id = read_short
      slot = read_short(false, :A) + 1
      interface = read_short(false, :A)
      item = context.inventory[:container].at(slot)
      return unless item # This check is for instances where a context may perform a 5thoptclick followed by this 2ndoptclick. this slot may be nil, so we do nothing and sort of force a proper click.

      old = context.equipment[item.definition[:slot]]
      context.equipment[item.definition[:slot]] = item
      context.inventory[:container].remove_at(slot)
      context.add_item(old, slot) if old.is_a?(RuneRb::Game::Item::Stack)
      update(:equipment)
      update(:inventory)
    when 16 # Third
      item_id = read_short(false, :ADD)
      slot = read_short(false, :ADD, :LITTLE)
      interface = read_short(false, :ADD, :LITTLE)
    when 75 # Fourth
      interface = read_short(false, :ADD, :LITTLE)
      slot = read_short(false, :STD, :LITTLE)
      item_id = read_short(false, :ADD, :BIG)
    when 87 # Fifth
      item_id = read_short(false, :ADD)
      interface = read_short
      slot = read_short(false, :A) + 1
    end

    log_item_click(interface, slot, item_id)
  end

  private

  # Logs the item click
  # @param interface [Integer] the interface ID
  # @param slot [Integer] the slot of the item
  # @param item [Integer] the item ID for the item
  def log_item_click(interface, slot, item)
    case interface
    when 3214
      log "Got Inventory Tab OptionClick: [slot]: #{slot} || [item]: #{item} || [interface]: #{interface}"
    when 1688
      log "Got Equipment Tab OptionClick: [slot]: #{slot} || [item]: #{item} || [interface]: #{interface}"
    else
      err "Unhandled OptionClick: [slot]: #{slot} || [item]: #{item} || [interface]: #{interface}"
    end
  end
end