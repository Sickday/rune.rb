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
  on_int_button(button) { |player| player.io.send_message "dicks #{i}" }
end


