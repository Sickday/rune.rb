module RuneRb::Network::RS377::OptionClickMessage
  include RuneRb::System::Log

  def parse(context)
    case @header[:op_code]
    when 203 # First
      interface = read_short(false, :ADD)
      slot = read_short(false, :STD, :LITTLE)
      item_id = read_short(true, :STD, :LITTLE)
    when 24 # Second
      interface = read_short(false, :STD, :LITTLE)
      item_id = read_short(false, :STD, :LITTLE)
      slot = read_short(false, :ADD) + 1
      item = context.inventory[:container].at(slot)
      return unless item # This check is for instances where a context may perform a 5thoptclick followed by this 2ndoptclick. this slot may be nil, so we do nothing and sort of force a proper click.

      old = context.equipment[item.definition[:slot]]
      context.equipment[item.definition[:slot]] = item
      context.inventory[:container].remove_at(slot)
      context.add_item(old, slot) if old.is_a?(RuneRb::Game::Item::Stack)
      update(:equipment)
      update(:inventory)
    when 161 # Third
      slot = read_short(false, :ADD, :LITTLE)
      item_id = read_short(false, :ADD, :LITTLE)
      interface = read_short(false, :STD, :LITTLE)
    when 228 # Fourth
      slot = read_short(false, :STD, :LITTLE)
      item_id = read_short(false, :ADD)
      interface = read_short
    when 4 # Fifth
      slot = read_short(false, :STD, :LITTLE)
      item_id = read_short(false, :ADD, :LITTLE)
      interface = read_short(false, :ADD, :LITTLE)
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
    else log! "OptionClick: [slot]: #{slot} || [item]: #{item} || [interface]: #{interface}"
    end
  end
end