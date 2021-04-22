module RuneRb::Network::RS317::OptionClickMessage
  include RuneRb::System::Log

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