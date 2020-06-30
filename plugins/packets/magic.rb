# Magic on NPC
on_packet(131) do |player, packet|
  id = packet.read_leshort_a.ushort
  spell = packet.read_short_a.ushort
  player.io.send_message "index: #{id}"
  player.io.send_message "spell: #{spell}"

  raise "invalid npc index: #{id}" unless (0...2000).include?(id)

  target = WORLD.npcs[id - 1]
  next unless player.location.within_interaction_distance?(target.location)

  handler = HOOKS[:magic_on_npc][spell]
  handler.call(player, target) if handler.instance_of?(Proc)
end

# Magic on player
on_packet(249) do |player, packet|
  id = packet.read_short_a.ushort
  spell = packet.read_leshort.ushort
  raise "invalid player index: #{id}" unless (0...2000).include?(id)

  target = WORLD.players[id - 1]
  next unless player.location.within_interaction_distance?(target.location)

  handler = HOOKS[:magic_on_player][spell]
  handler.call(player, target) if handler.instance_of?(Proc)
end

# Magic on inventory item
on_packet(237) do |player, packet|
  item_slot = packet.read_short
  item_id = packet.read_short_a
  interface_id = packet.read_short
  spell = packet.read_short_a

  raise "invalid used slot #{item_slot} in interface #{interface_id}" unless valid_int_slot?(item_slot, interface_id)

  handler = HOOKS[:magic_on_item][spell]

  handler.call(player, item_id, item_slot) if handler.instance_of?(Proc)
end

# Magic on floor item
on_packet(181) do |player, packet|
  item_y = packet.read_leshort
  item_id = packet.read_short.ushort
  item_x = packet.read_leshort
  spell = packet.read_short_a.ushort
  item = WORLD.region_manager.get_surrounding_regions(player.location).inject([]) { |all, region| all + region.ground_items }.find do |item|
    item.item.id == item_id && item.location.x == item_x && item.location.y == item_y
  end

  next if item.nil?
  next unless player.location.within_interaction_distance?(item.location)

  handler = HOOKS[:magic_on_flooritem][[item_id, spell]]
  player.walking_queue.reset
  handler.call(player, item) if handler.instance_of?(Proc)
end
