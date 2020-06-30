# Listener
on_player_login(:inventory) do |player|
  player.inventory.add_listener(RuneRb::Item::InterfaceContainerListener.new(player, 3214))
  player.inventory.add_listener(RuneRb::Item::WeightListener.new(player))
end
on_player_login(:move_speed) do |player|
  value = player.settings[:move_speed]
  player.walking_queue.run_toggle = value == 1
  player.io.send_config(173, (player.settings[:move_speed] || 0))
end
on_player_login(:chat_effects) { |player| player.io.send_config(171, player.settings[:chat_effects] || 0) }
on_player_login(:mouse_buttons) { |player| player.io.send_config(170, player.settings[:mouse_buttons] || 0) }
on_player_login(:brightness) { |player| player.io.send_config(166, player.settings[:brightness] || 2) }
# Send message on login
on_player_login(:mute) do |player|
  player.io.send_message('You have been muted for breaking a rule.') if player.settings[:muted]
end

# Login
on_player_login(:pm) do |player|
  player.varp.friends ||= []
  player.varp.ignores ||= []
  player.var.pm = RuneRb::PM::Presence.new(player)
end

# Logout
on_player_logout(:pm) { |player| player.var.pm.unregistered }