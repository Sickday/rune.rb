def valid_int_slot?(slot, interface_id)
  HOOKS[:int_size].key?(interface_id) && HOOKS[:int_size][interface_id].kind_of?(Integer) && (0...HOOKS[:int_size][interface_id]) === slot
end

# Item first click
on_packet(122) do |player, packet|
  # Read values
  interface_id = packet.read_leshort_a.ushort
  slot = packet.read_short_a.ushort
  id = packet.read_leshort.ushort
  # Make sure the input is valid
  raise "unhandled interface id #{interface_id}" unless interface_id == 3214
  next unless player.inventory.is_slot_used(slot) && player.inventory.items[slot].id == id

  handler = HOOKS[:item_click1][id]
  handler.call(player, slot) if handler.instance_of?(Proc)
end

# Item second click
on_packet(75) do |player, packet|
  interface_id = packet.read_leshort_a.ushort
  slot = packet.read_leshort.ushort
  item_id = packet.read_short_a.ushort
  raise "unhandled interface id #{interface_id}" unless interface_id == 3214
  next unless player.inventory.is_slot_used(slot) && player.inventory.items[slot].id == item_id

  handler = HOOKS[:item_click2][item_id]
  handler.call(player, slot) if handler.instance_of?(Proc)
end

# Item option 1
on_packet(145) do |player, packet|
  interface_id = packet.read_short_a.ushort
  slot = packet.read_short_a.ushort
  id = packet.read_short_a.ushort
  raise "invalid slot #{slot} in interface #{interface_id}" unless valid_int_slot?(slot, interface_id)

  handler = HOOKS[:item_option1][interface_id]
  handler.call(player, id, slot) if handler.instance_of?(Proc)
end

# Item option 2
on_packet(117) do |player, packet|
  interface_id = packet.read_leshort_a.ushort
  id = packet.read_leshort_a.ushort
  slot = packet.read_leshort.ushort
  raise "invalid slot #{slot} in interface #{interface_id}" unless valid_int_slot?(slot, interface_id)

  handler = HOOKS[:item_option2][interface_id]
  handler.call(player, id, slot) if handler.instance_of?(Proc)
end

# Item option 3
on_packet(43) do |player, packet|
  interface_id = packet.read_leshort.ushort
  id = packet.read_short_a.ushort
  slot = packet.read_short_a.ushort
  raise "invalid slot #{slot} in interface #{interface_id}" unless valid_int_slot?(slot, interface_id)

  handler = HOOKS[:item_option3][interface_id]
  handler.call(player, id, slot) if handler.instance_of?(Proc)
end

# Item option 4
on_packet(129) do |player, packet|
  slot = packet.read_short_a.ushort
  interface_id = packet.read_short.ushort
  id = packet.read_short_a.ushort
  raise "invalid slot #{slot} in interface #{interface_id}" unless valid_int_slot?(slot, interface_id)

  handler = HOOKS[:item_option4][interface_id]
  handler.call(player, id, slot) if handler.instance_of?(Proc)
end

# Item option 5
on_packet(135) do |player, packet|
  slot = packet.read_leshort.ushort
  interface_id = packet.read_short_a.ushort
  id = packet.read_leshort.ushort
  raise "invalid slot #{slot} in interface #{interface_id}" unless valid_int_slot?(slot, interface_id)

  if HOOKS[:int_enteramount].key?(interface_id) && HOOKS[:int_enteramount][interface_id].kind_of?(Proc)
    player.interface_state.open_amount_interface(interface_id, slot, id)
  end
end

# Item wield
on_packet(41) do |player, packet|
  id = packet.read_short.ushort
  slot = packet.read_short_a.ushort
  interface_id = packet.read_short_a.ushort
  raise "invalid slot #{slot} in interface #{interface_id}" unless valid_int_slot?(slot, interface_id)

  handler = HOOKS[:item_wield][interface_id]
  item = player.inventory.items[slot]
  name = item.definition.name
  handler.call(player, item, slot, name, id) if handler.instance_of?(Proc)
end

# Item drop
on_packet(87) do |player, packet|
  id = packet.read_short_a.ushort
  interface_id = packet.read_short.ushort
  slot = packet.read_short_a.ushort
  raise "dropping from non-inventory #{interface_id}" unless interface_id == 3214
  raise "invalid slot #{slot} in interface #{interface_id}" unless valid_int_slot?(slot, interface_id)

  item = player.inventory.items[slot]
  if item.id == id
    gitem = RuneRb::GroundItems::GroundItem.new(player, item)
    player.io.send_grounditem_creation(gitem)
    WORLD.submit_event(gitem.life)
    player.inventory.remove(slot, item)
  end
end

# Item pick up
on_packet(236) do |player, packet|
  item_y = packet.read_leshort.ushort
  item_id = packet.read_short.ushort
  item_x = packet.read_leshort.ushort
  loc = RuneRb::Model::Location.new item_x, item_y, player.location.z
  item = nil

  # Check if this item is a world item
  world_item = false
  RuneRb::World::ItemSpawns.items.each do |i|
    if !i.picked_up && i.item.id == item_id && i.location == loc
      world_item = true
      item = i
    end
  end

  unless world_item
    item = WORLD.region_manager.get_surrounding_regions(player.location).inject([]) { |all, region| all + region.ground_items }.find do |item|
      item.item.id == item_id && item.location.x == loc.x && item.location.y == loc.y
    end
  end

  unless item.nil?
    player.face(item.location) if item.on_table
    player.play_animation RuneRb::Model::Animation.new(832, 10) if item.on_table
    player.action_queue.add(RuneRb::GroundItems::PickupItemAction.new(player, item))
  end
end

# Item alt 2
on_packet(16) do |player, packet|
  item_id = packet.read_short_a.ushort
  slot = packet.read_leshort_a.ushort
  interface_id = packet.read_leshort_a.ushort
  raise "unhandled interface id #{interface_id}" unless interface_id == 3214
  next unless player.inventory.is_slot_used(slot) && player.inventory.items[slot].id == item_id

  handler = HOOKS[:item_alt2][item_id]
  handler.call(player, slot) if handler.instance_of?(Proc)
end

# Item on ground
on_packet(253) do |player, packet|
  item_x = packet.read_short_a.ushort
  item_y = packet.read_short.ushort
  item_id = packet.read_short_a.ushort
  item = WORLD.region_manager.get_surrounding_regions(player.location).inject([]) { |all, region| all + region.ground_items }.find do |item|
    item.item.id == item_id && item.location.x == item_x && item.location.y == item_y
  end
  next if item.nil?
  next unless player.location.within_interaction_distance?(item.location)

  handler = HOOKS[:item_on_ground][item_id]
  handler.call(player, item) if handler.instance_of?(Proc)
end

# Switch item
on_packet(214) do |player, packet|
  interface_id = packet.read_leshort_a
  packet.read_byte_c # ?
  from_slot = packet.read_leshort_a
  to_slot = packet.read_leshort
  raise "invalid oldSlot #{from_slot} in interface #{interface_id}" unless valid_int_slot?(from_slot, interface_id)
  raise "invalid new slot #{to_slot} in interface #{interface_id}" unless valid_int_slot?(to_slot, interface_id)
  raise 'same slot' unless to_slot != from_slot

  handler = HOOKS[:item_swap][interface_id]
  handler.call(player, from_slot, to_slot) if handler.instance_of?(Proc)
end

# Item on interface item
on_packet(53) do |player, packet|
  target_slot = packet.read_short.ushort
  used_slot = packet.read_short_a.ushort
  packet.read_short # ?
  interface_id = packet.read_short.ushort

  raise "invalid used slot #{used_slot} in interface #{interface_id}" unless valid_int_slot?(used_slot, interface_id)
  raise "invalid target slot #{target_slot} in interface #{interface_id}" unless valid_int_slot?(target_slot, interface_id)

  used_item = player.inventory.items[used_slot].id
  target_item = player.inventory.items[target_slot].id
  ingredients = [used_item, target_item].sort
  handler = HOOKS[:item_on_item][ingredients]
  handler.instance_of?(Proc) ? handler.call(player) : player.io.send_message('Nothing interesting happens.')
end

# Item on floor item
on_packet(25) do |player, packet|
  interface_id = packet.read_leshort.ushort
  item_id = packet.read_short_a.ushort
  floor_id = packet.read_short.ushort
  floor_y = packet.read_short_a.ushort
  item_slot = packet.read_leshort_a.ushort
  floor_x = packet.read_short.ushort

  # TODO Send grounditem object to proc

  raise "invalid used slot #{item_slot} in interface #{interface_id}" unless valid_int_slot?(item_slot, interface_id)

  handler = HOOKS[:item_on_floor][[item_id, floor_id]]
  handler.instance_of?(Proc) ? handler.call(player) : player.io.send_message('Nothing interesting happens.')
end

# Item on object
on_packet(192) do |player, packet|
  packet.read_leshort_a # ?
  obj_id = packet.read_leshort.ushort
  obj_y = packet.read_leshort_a.ushort
  slot = packet.read_leshort.ushort
  obj_x = packet.read_leshort_a.ushort
  item_id = packet.read_short.ushort
  loc = RuneRb::Model::Location.new obj_x, obj_y, player.location.z
  next unless player.location.within_interaction_distance?(loc)

  player.used_loc = loc
  player.used_item = item_id
  handler = HOOKS[:item_on_obj][[item_id, obj_id]]
  handler.instance_of?(Proc) ? handler.call(player) : player.io.send_message('Nothing interesting happens.')
end

# Item on player
on_packet(14) do |player, packet|
  interface_id = packet.read_short_a
  player_used = WORLD.players[packet.read_short - 1]
  item_id = packet.read_short
  item_slot = packet.read_leshort
  next unless player.location.within_interaction_distance?(player_used.location)
  raise "invalid used slot #{item_slot} in interface #{interface_id}" unless valid_int_slot?(item_slot, interface_id)

  handler = HOOKS[:item_on_player][item_id]
  handler.call(player, player_used) if handler.instance_of?(Proc)
end

# Item on NPC
on_packet(57) do |player, packet|
  item_id = packet.read_short_a
  npc = WORLD.npcs[packet.read_short_a - 1]
  item_slot = packet.read_leshort
  interface_id = packet.read_short_a
  next unless player.location.within_interaction_distance?(npc.location)
  raise "invalid used slot #{item_slot} in interface #{interface_id}" unless valid_int_slot?(item_slot, interface_id)

  handler = HOOKS[:item_on_npc][[item_id, npc.definition.id]]
  handler.call(player, npc) if handler.instance_of?(Proc)
end

# Interface container sizes
set_int_size(3214, 28)

# Item swap
on_item_swap(3214) do |player, from_slot, to_slot|
  player.inventory.swap(from_slot, to_slot)
end
