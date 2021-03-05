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

module RuneRb::Game::Entity::Helpers::Click

  # Attempts to parse an action click
  # @param type [Symbol] the type of action click to parse
  # @param message [RuneRb::Network::Message] the message to parse
  def parse_action(type, message)
    case type
    when :first_action then parse_first_action(message)
    when :second_action then parse_second_action(message)
    when :switch_item then parse_switch_item(message)
    when :mouse_click then parse_mouse_click(message)
    else
      err "Unrecognized action type: #{type}"
    end
  end

  # Parses an option click
  # @param type [Symbol] the type of option click to parse
  # @param message [RuneRb::Network::Message] the message to parse
  def parse_option(type, message)
    case type
    when :first_option then parse_first_option(message)
    when :second_option then parse_second_option(message)
    when :third_option then parse_third_option(message)
    when :fourth_option then parse_fourth_option(message)
    when :fifth_option then parse_fifth_option(message)
    else
      err "Unrecognized option type: #{type}"
    end
  end

  private

  # Parses a left or right click of the mouse
  # @param message [RuneRb::Network::Message] the message payload to parse
  def parse_mouse_click(message)
    value = message.read(:int, signed: false, mutation: :STD, order: :BIG)
    delay = (value >> 20) * 50
    right = (value >> 19 & 0x1) == 1
    coords = value & 0x3FFFF
    x = coords % 765
    y = coords / 765
    return unless RuneRb::GLOBAL[:DEBUG]

    log RuneRb::GLOBAL[:COLOR].blue((right ? 'Right' : 'Left') + "Mouse Click at #{RuneRb::GLOBAL[:COLOR].cyan("Position: x: #{x}, y: #{y}, delay: #{delay}")}")
  end

  # Parse a 1stItemOptionClick
  # @param message [RuneRb::Network::Message] the incoming message
  def parse_first_option(message)
    interface = message.read(type: :short, signed: false, mutation: :A, order: :LITTLE)
    slot = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    item_id = message.read(type: :short, signed: false, mutation: :STD, order: :LITTLE)
    case interface
    when 3214
      log "Got Inventory Tab 1stOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688
      log "Got Equipment Tab 1stOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unhandled 1stOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end

  # Parse a 2ndItemOptionClick
  # @param message [RuneRb::Network::Message] the message to read from
  def parse_second_option(message)
    item_id = message.read(type: :short, signed: false, mutation: :STD, order: :BIG)
    slot = message.read(type: :short, signed: false, mutation: :A, order: :BIG) + 1
    interface = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    case interface
    when 3214
      item = @inventory[:container].at(slot)
      return unless item # This check is for instances where a context may perform a 5thoptclick followed by this 2ndoptclick. this slot may be nil, so we do nothing and sort of force a proper click.

      old = @equipment[item.definition[:slot]]
      @equipment[item.definition[:slot]] = item
      @inventory[:container].remove_at(slot)
      add_item(old, slot) if old.is_a?(RuneRb::Game::Item::Stack)
      update(:equipment)
      update(:inventory)
      log "Got Inventory Tab 2ndOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface} || [old]: #{old.is_a?(Integer) ? old : old.id}"
    when 1688
      log "Got Equipment Tab 2ndOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unhandled 2ndOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end

  # Parse a 3rdItemOptionClick
  # @param message [RuneRb::Network::Message] the message to read from.
  def parse_third_option(message)
    item_id = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    slot = message.read(type: :short, signed: false, mutation: :A, order: :LITTLE)
    interface = message.read(type: :short, signed: false, mutation: :A, order: :LITTLE)
    case interface
    when 3214
      log "Got Inventory Tab 3rdOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688
      log "Got Equipment Tab 3rdOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unhandled 3rdOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end

  # Parse a 4thItemOptionClick
  # @param message [RuneRb::Network::Message]
  def parse_fourth_option(message)
    interface = message.read(type: :short, signed: false, mutation: :A, order: :LITTLE)
    slot = message.read(type: :short, signed: false, mutation: :STD, order: :LITTLE)
    item_id = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    case interface
    when 3214
      log "Got Inventory Tab 4thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688
      log "Got Equipment Tab 4thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unhandled 4thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end

  # Parse a 5thItemOptionClick
  # @param message [RuneRb::Network::Message] the message to read from
  def parse_fifth_option(message)
    item_id = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    interface = message.read(type: :short, signed: false, mutation: :STD, order: :BIG)
    slot = message.read(type: :short, signed: false, mutation: :A, order: :BIG) + 1
    case interface
    when 3214
      return unless @inventory[:container].has?(item_id, slot)

      ## TODO: Implement and call create ground item
      @inventory[:container].remove_at(slot)
      update(:inventory)
      log "Got Inventory 5thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688
      log "Got Equipment 5thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unrecognized 5thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end

  # Parses a switch item click
  # @param message [RuneRb::Network::Message] the message to parse from.
  def parse_switch_item(message)
    interface = message.read(type: :short, signed: false, mutation: :A, order: :LITTLE)
    inserting = message.read(type: :byte, signed: false, mutation: :C, order: :BIG) # This will matter when bank is implemented. TODO: impl bank
    old_slot = message.read(type: :short, signed: false, mutation: :A, order: :LITTLE)
    new_slot = message.read(type: :short, signed: false, mutation: :STD, order: :LITTLE)
    case interface
    when 3214
      if old_slot >= 0 &&
         new_slot >= 0 &&
         old_slot <= @inventory[:container].limit &&
         new_slot <= @inventory[:container].limit
        @inventory[:container].swap(old_slot, new_slot)
        update(:inventory)
      end
      log "Got Inventory SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{inserting} || [interface]: #{interface}"
    when 1688
      log "Got Equipment SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{inserting} || [interface]: #{interface}"
    else
      err "Unrecognized SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{inserting} || [interface]: #{interface}"
    end
  end

  # Parses a first action click
  # @param message [RuneRb::Network::Message] the message to read from.
  def parse_first_action(message)
    interface = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    slot = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    item_id = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    case interface
    when 3214 # Inventory = EquipItem or Eat food, or break a teletab (not really)
      log "Got Inventory Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688 # EquipmentTab
      if add_item(RuneRb::Game::Item::Stack.new(item_id))
        unequip(slot)
        update(:equipment)
        update(:inventory)
      else
        @session.write_text("You don't have enough space in your inventory to do this.")
      end
      log "Got Equipment Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unrecognized 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end

  # Parses a second action click
  # @param message [RuneRb::Network::Message] the message to read from
  def parse_second_action(message)
    item_id = message.read_short(type: :short, signed: false, mutation: :STD, order: :BIG)
    slot = message.read(type: :short, signed: false, mutation: :A, order: :BIG)  + 1 # This is the Slot that was clicked.
    interface = message.read(type: :short, signed: false, mutation: :A, order: :BIG)
    case interface
    when 3214 # Inventory Tab
      log "Got Inventory Tab 2ndActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688 # Equipment Tab
      log "Got Equipment Tab 2ndActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unrecognized 2ndActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end
end