module RuneRb::Network::RS317::ActionClickMessage
  include RuneRb::System::Log

  # Parses the ActionClickMessage
  # @param context [RuneRb::Game::Entity::Context] the context to parse for
  def parse(context)
    case @header[:op_code]
    when 145 # First
      interface = read_short(false, :ADD)
      slot = read_short(false, :ADD)
      item_id = read_short(false, :ADD)

      # Equipping items.
      if context.add_item(RuneRb::Game::Item::Stack.new(item_id)) && interface == 1688
        context.unequip(slot)
        context.update(:equipment)
        context.update(:inventory)
      else
        @session.write_message(:sys_text, message: "You don't have enough space in your inventory to do this.")
      end
    when 117 # Second
      interface = read_short(false, :ADD, :LITTLE)
      item_id = read_short(false, :ADD, :LITTLE)
      slot = read_short(false, :STD, :LITTLE)
    when 43 # Third
      interface = read_short(false, :STD, :LITTLE)
      item_id = read_short(false, :ADD)
      slot = read_short(false, :ADD)
    when 129 # Fourth
      slot = read_short(false, :ADD)
      interface = read_short
      item_id = read_short(false, :ADD)
    when 135 # Fifth
      slot = read_short(false, :STD, :LITTLE)
      interface = read_short(false, :ADD)
      item_id = read_short(false, :STD, :LITTLE)
    end
    log_action_click(interface, slot, item_id)
  end

  private

  # Logs the action click
  # @param interface [Integer] the interface ID of the interface where the action ocurred
  # @param slot [Integer] the slot of the item
  # @param item_id [Integer] the item ID
  def log_action_click(interface, slot, item_id)
    case interface
    when 3214 # Inventory = EquipItem or Eat food, or break a teletab (not really)
      log "Got Inventory Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688 # EquipmentTab
      log "Got Equipment Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else log! "ActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
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
