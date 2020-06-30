# Idle logout
on_packet(202) do |player, packet|
  player.io.send_logout unless player.rights == :admin
end

# Character design
on_packet(101) do |player, packet|
  gender = packet.read_byte
  head = packet.read_byte
  beard = packet.read_byte
  torso = packet.read_byte
  arms = packet.read_byte
  hands = packet.read_byte
  legs = packet.read_byte
  feet = packet.read_byte
  hair_col = packet.read_byte
  torso_col = packet.read_byte
  leg_col = packet.read_byte
  feet_col = packet.read_byte
  skin_col = packet.read_byte

  look = [gender, hair_col, torso_col, leg_col, feet_col,
          skin_col, head, torso, arms, hands, legs, feet, beard]

  player.appearance.set_look(look)
  player.interface_state.interface_closed
  player.flags.set(:appearance, true)
end
