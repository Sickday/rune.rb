module RuneRb::Entity::Helpers::Click

  # Attempts to parse an action click
  # @param type [Symbol] the type of action click to parse
  # @param frame [RuneRb::Net::Frame] the frame to parse
  def parse_action(type, frame)
    case type
    when :first_action then parse_first_action(frame)
    when :second_action then parse_second_action(frame)
    when :switch_item then parse_switch_item(frame)
    when :mouse_click then parse_mouse_click(frame)
    else
      err "Unrecognized action type: #{type}"
    end
  end

  # Parses an option click
  # @param type [Symbol] the type of option click to parse
  # @param frame [RuneRb::Net::Frame] the frame to parse
  def parse_option(type, frame)
    case type
    when :first_option then parse_first_option(frame)
    when :second_option then parse_second_option(frame)
    when :third_option then parse_third_option(frame)
    when :fourth_option then parse_fourth_option(frame)
    when :fifth_option then parse_fifth_option(frame)
    else
      err "Unrecognized option type: #{type}"
    end
  end

  private

  # Parses a left or right click of the mouse
  # @param frame [RuneRb::Net::Frame] the frame payload to parse
  def parse_mouse_click(frame)
    value = frame.read_int(false)
    delay = (value >> 20) * 50
    right = (value >> 19 & 0x1) == 1
    coords = value & 0x3FFFF
    x = coords % 765
    y = coords / 765
    return unless RuneRb::DEBUG

    log RuneRb::COL.blue((right ? 'Right' : 'Left') + "Mouse Click at #{RuneRb::COL.cyan("Position: x: #{x}, y: #{y}, delay: #{delay}")}")
  end

  # Parse a 1stItemOptionClick
  # @param frame [RuneRb::Net::Frame] the incoming frame
  def parse_first_option(frame)
    interface = frame.read_short(false, :A, :LITTLE)
    slot = frame.read_short(false, :A)
    item_id = frame.read_short(false, :STD, :LITTLE)
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
  # @param frame [RuneRb::Net::Frame] the frame to read from
  def parse_second_option(frame)
    item_id = frame.read_short(false)
    slot = frame.read_short(false, :A) + 1
    interface = frame.read_short(false, :A)
    case interface
    when 3214
      item = @inventory[:container].at(slot)
      return unless item # This check is for instances where a context may perform a 5thoptclick followed by this 2ndoptclick. this slot may be nil, so we do nothing and sort of force a proper click.

      old = @equipment[item.definition[:slot]]
      @equipment[item.definition[:slot]] = item
      @inventory[:container].remove_at(slot)
      add_item(old, slot) if old.is_a?(RuneRb::Item::Stack)
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
  # @param frame [RuneRb::Net::Frame] the frame to read from.
  def parse_third_option(frame)
    item_id = frame.read_short(false, :A)
    slot = frame.read_short(false, :A, :LITTLE)
    interface = frame.read_short(false, :A, :LITTLE)
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
  # @param frame [RuneRb::Net::Frame]
  def parse_fourth_option(frame)
    interface = frame.read_short(false, :A, :LITTLE)
    slot = frame.read_short(false, :STD, :LITTLE)
    item_id = frame.read_short(false, :A)
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
  # @param frame [RuneRb::Net::Frame] the frame to read from
  def parse_fifth_option(frame)
    item_id = frame.read_short(false, :A)
    interface = frame.read_short(false)
    slot = frame.read_short(false, :A) + 1
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
  # @param frame [RuneRb::Net::Frame] the frame to parse from.
  def parse_switch_item(frame)
    interface = frame.read_short(false, :A, :LITTLE)
    inserting = frame.read_byte(false, :C) # This will matter when bank is implemented. TODO: impl bank
    old_slot = frame.read_short(false, :A, :LITTLE)
    new_slot = frame.read_short(false, :STD, :LITTLE)
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
  # @param frame [RuneRb::Net::Frame] the frame to read from.
  def parse_first_action(frame)
    interface = frame.read_short(false, :A)
    slot = frame.read_short(false, :A)
    item_id = frame.read_short(false, :A)
    case interface
    when 3214 # Inventory = EquipItem or Eat food, or break a teletab (not really)
      log "Got Inventory Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688 # EquipmentTab
      if add_item(RuneRb::Item::Stack.new(item_id))
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
  # @param frame [RuneRb::Net::Frame] the frame to read from
  def parse_second_action(frame)
    item_id = frame.read_short(false)
    slot = frame.read_short(false, :A)  + 1 # This is the Slot that was clicked.
    interface = frame.read_short(false, :A)
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