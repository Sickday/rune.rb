module RuneRb::Network::RS317::ActionClickMessage
  include RuneRb::System::Log

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

  def log_action_click(interface, slot, item_id)
    case interface
    when 3214 # Inventory = EquipItem or Eat food, or break a teletab (not really)
      log "Got Inventory Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    when 1688 # EquipmentTab
      log "Got Equipment Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    else
      err "Unrecognized 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
    end
  end
end