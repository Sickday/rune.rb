# Walking
on_packet(164, 248, 98) do |player, packet|
  # Calculate step length
  size = packet.buffer.size
  size -= 14 if packet.opcode == 248 # Minimap
  steps = (size - 5) / 2

  # Reset walking queue and actions
  player.walking_queue.reset
  player.action_queue.clear_non_walkable
  player.io.send_clear_screen
  player.reset_interacting_entity

  first_x = packet.read_leshort_a
  path = []
  steps.times { path << [packet.read_byte, packet.read_byte] }
  first_y = packet.read_leshort
  run_queue = packet.read_byte_c == 1 && player.settings[:energy] >= 1.0

  player.walking_queue.run_queue = run_queue
  player.walking_queue.add_step(first_x, first_y)

  path.each do |step|
    x = step[0] + first_x
    y = step[1] + first_y
    player.walking_queue.add_step(x, y)
  end

  player.walking_queue.finish
end

# Enter new region
on_packet(210) do |player, packet|
  # Update objects
  WORLD.object_manager.objects.each { |object| object.change(player) if object.location.within_distance?(player.location) }
  # Update NPC faces
  WORLD.region_manager.get_local_npcs(player).each { |npc| npc.flags.flag(:face_coord) unless npc.direction.nil? }
  # Spawn local world items
  RuneRb::World::ItemSpawns.items.each { |item| item.spawn(player) if !item.picked_up && item.within_distance?(player) }
end

# Player option 1 (Attack)
on_packet(128) do |player, packet|
  id = packet.read_short.ushort
  raise "invalid player index: #{id}" unless (0...2000) === id

  victim = WORLD.players[id - 1]
  if !victim.nil? && player.location.within_interaction_distance?(victim.location)
    player.action_queue << AttackAction.new(player, victim)
  end
end

# Player option 2 (Follow)
on_packet(73) do |player, packet|
  id = packet.read_short.ushort
  raise "Invalid player index: #{id}" unless (0...2000).include?(id)
end