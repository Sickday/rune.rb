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
on_packet(130) do |player, _packet|
  handler = HOOKS[:int_close][player.interface_state.current_interface]
  handler.instance_of?(Proc) ? handler.call(player) : player.interface_state.interface_closed
end

# Interface Equip container sizes
set_int_size(1688, 14)
# Interface Bank container sizes
set_int_size(5382, 352)
set_int_size(5064, 28)
# Interface Inventory container sizes
set_int_size(3214, 28)
# Interface Trade container(s) sizes
set_int_size(3322, 28)
set_int_size(3415, 28)
# Interface Shop + invent container sizes
set_int_size(3900, 40)
set_int_size(3823, 28)

###
# TELEPORTS
# Varrock
on_int_button(1164) { |player| player.teleport_location = RuneRb::Model::Location.new(3210, 3424, 0) }
# Lumbridge
on_int_button(1167) { |player| player.teleport_location = RuneRb::Model::Location.new(3222, 3218, 0) }
# Falador
on_int_button(1170) { |player| player.teleport_location = RuneRb::Model::Location.new(2964, 3378, 0) }
# Camelot
on_int_button(1174) { |player| player.teleport_location = RuneRb::Model::Location.new(2757, 3478, 0) }
# Ardougne
on_int_button(1540) { |player| player.teleport_location = RuneRb::Model::Location.new(2662, 3305, 0) }
# Watchtower
on_int_button(1541) { |player| player.teleport_location = RuneRb::Model::Location.new(2549, 3113, 0) }
# Trollheim
on_int_button(7455) { |player| player.teleport_location = RuneRb::Model::Location.new(2891, 3678, 0) }
# Ape atoll
on_int_button(18_470) { |player| player.teleport_location = RuneRb::Model::Location.new(2795, 2799, 0) }

##
# BANKING
# Bank window mode buttons
on_int_button(5386) { |player| player.settings[:withdraw_note] = true }
on_int_button(5387) { |player| player.settings[:withdraw_note] = false }
on_int_button(8130) { |player| player.settings[:swapping] = true }
on_int_button(8131) { |player| player.settings[:swapping] = false }
# Enter amount withdraw/deposit
on_int_enter_amount(5064) { |player, id, slot, amount| Bank.deposit(player, slot, id, amount) }
on_int_enter_amount(5382) { |player, id, slot, amount| Bank.withdraw(player, slot, id, amount) }


##
# COOKING
on_int_button(13_720) { |player| player.action_queue.add(Cooking::CookAction.new(player, player.used_loc, player.used_item)) }
on_int_button(13_719) { |player| player.action_queue.add(Cooking::CookAction.new(player, player.used_loc, player.used_item, 5)) }
on_int_button(13_717) { |player| player.action_queue.add(Cooking::CookAction.new(player, player.used_loc, player.used_item, player.inventory.count(player.used_item))) }
on_int_button(13_718) { |player| player.interface_state.open_amount_interface(1743, -1, -1) }
# Enter amount
on_int_enter_amount(1743) do |player, _enterAmountId, _enterAmountSlot, amount|
  player.action_queue.add(Cooking::CookAction.new(player, player.used_loc, player.used_item, amount))
end


###
# SETTINGS
# Run settings
on_int_button(152) do |player|
  player.walking_queue.run_toggle = false
  player.settings[:move_speed] = 0
end

on_int_button(153) do |player|
  if player.settings[:energy] < 1.0
    # Not enough energy to enable
    player.walking_queue.run_toggle = false
    player.settings[:move_speed] = 0
    player.io.send_config 173, 0
  else
    player.walking_queue.run_toggle = true
    player.settings[:move_speed] = 1
  end
end
# Brightness
[[5451, 5452], [6157, 6273], [6274, 6275], [6276, 6277]].each_with_index do |buttons, i|
  buttons.each do |button|
    on_int_button(button) { |player| player.settings[:brightness] = i + 1 }
  end
end
# Mouse buttons
[6278, 6279].each_with_index do |button, i|
  on_int_button(button) { |player| player.settings[:mouse_buttons] = i }
end
# Chat effects
[6280, 6281].each_with_index do |button, i|
  on_int_button(button) { |player| player.settings[:chat_effects] = i }
end
[953, 952].each_with_index do |button, i|
  on_int_button(button) { |player| player.io.send_message("Button index: #{i}") }
end
###
# TRADE
##
# Accept offer button
on_int_button(3420) { |player| Trade.accept(player) }
on_int_button(3546) { |player| Trade.accept(player) }
##
# LOGOUT
on_int_button(2458) { |player| player.io.send_logout }
##
# EMOTES
{161 => 860,
 162 => 857,
 163 => 863,
 164 => 858,
 165 => 859,
 166 => 866,
 167 => 864,
 168 => 855,
 169 => 856,
 170 => 861,
 171 => 862,
 172 => 865,
 13_362 => 2105,
 13_363 => 2106,
 13_364 => 2107,
 13_365 => 2108,
 13_366 => 2109,
 13_367 => 2110,
 13_368 => 2111,
 13_383 => 2127,
 13_384 => 2128,
 13_369 => 2112,
 13_370 => 2113,
 11_100 => 1368,
 667 => 1131,
 6503 => 1130,
 6506 => 1129,
 666 => 1128}.each do |button, anim|
  on_int_button(button) { |player| player.play_animation(RuneRb::Model::Animation.new(anim)) }
end