on_player_login(:move_speed) do |player|
  value = player.settings[:move_speed]
  player.walking_queue.run_toggle = value == 1
  player.io.send_config(173, (player.settings[:move_speed] || 0))
end
on_player_login(:chat_effects) { |player| player.io.send_config(171, player.settings[:chat_effects] || 0) }
on_player_login(:mouse_buttons) { |player| player.io.send_config(170, player.settings[:mouse_buttons] || 0) }
on_player_login(:brightness) { |player| player.io.send_config(166, player.settings[:brightness] || 2) }