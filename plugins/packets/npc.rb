# NPC attack
on_packet(72) do |player, packet|
  npc_slot = packet.read_short_a.ushort
  npc = WORLD.npcs[npc_slot - 1]
  next unless player.location.within_interaction_distance?(npc.location)

  handler = HOOKS[:npc_attack][npc.definition.id]
  handler.call(player, npc) if handler.instance_of?(Proc)
end


# NPC option 1
on_packet(155) do |player, packet|
  npc_slot = packet.read_leshort.ushort
  npc = WORLD.npcs[npc_slot - 1]
  next unless player.location.within_interaction_distance?(npc.location)

  handler = HOOKS[:npc_option1][npc.definition.id]
  handler.call(player, npc) if handler.instance_of?(Proc)
end

# NPC option 2
on_packet(17) do |player, packet|
  npc_slot = packet.read_leshort_a.ushort
  npc = WORLD.npcs[npc_slot - 1]
  next unless player.location.within_interaction_distance?(npc.location)

  handler = HOOKS[:npc_option2][npc.definition.id]
  handler.call(player, npc) if handler.instance_of?(Proc)
end

# NPC option 3
on_packet(21) do |player, packet|
  npc_slot = packet.read_leshort_a.ushort
  npc = WORLD.npcs[npc_slot - 1]
  next unless player.location.within_interaction_distance?(npc.location)

  handler = HOOKS[:npc_option3][npc.definition.id]
  handler.call(player, npc) if handler.instance_of?(Proc)
end