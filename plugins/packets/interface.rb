# Action buttons
on_packet(185) do |player, packet|
  button = packet.read_short
  handler = HOOKS[:int_button][button]
  handler.instance_of?(Proc) ? handler.call(player) : Logging.logger['packets'].warn("Unhandled action button: #{button}")
end

# Enter amount
# TODO Reset interface ID at end
on_packet(208) do |player, packet|
  amount = packet.read_int
  if player.interface_state.enter_amount_open?
    enter_amount_slot = player.interface_state.enter_amount_slot
    enter_amount_id = player.interface_state.enter_amount_id
    handler = HOOKS[:int_enteramount][player.interface_state.enter_amount_interface]
    handler.call(player, enter_amount_id, enter_amount_slot, amount) if handler.instance_of?(Proc)
  end
end

# Close interface
on_packet(130) do |player, packet|
  handler = HOOKS[:int_close][player.interface_state.current_interface]
  handler.instance_of?(Proc) ? handler.call(player) : player.interface_state.interface_closed
end