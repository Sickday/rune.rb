module RuneRb::Network::RS377::SwitchItemMessage
  include RuneRb::System::Log

  def parse(context)
    new_slot = read_short(false, :ADD, :LITTLE)
    _insert = read_byte(false, :ADD).positive? # This will matter when bank is implemented. TODO: impl bank
    interface = read_short(false, :ADD)
    old_slot = read_short(false, :STD, :LITTLE)

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
    else log! "Unrecognized SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{_insert} || [interface]: #{interface}"
    end
  end
end