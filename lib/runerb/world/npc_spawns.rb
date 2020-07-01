module RuneRb::World
  class NPCSpawns
    def self.load
      XmlSimple.xml_in('data/npc_spawns.xml')['npc'].each_with_index { |row, _idx| NPCSpawns.spawn(row) }
    end

    def self.spawn(data)
      npc = RuneRb::NPC::NPC.new RuneRb::NPC::NPCDefinition.for_id(data['id'].to_i)
      npc.location = RuneRb::Model::Location.new(data['x'].to_i, data['y'].to_i, data['z'].to_i)
      WORLD.register_npc(npc)

      if data.include?('face')
        npc.direction = data['face'].to_sym
        offsets = NPC_DIRECTIONS[npc.direction]
        npc.face(npc.location.transform(offsets[0], offsets[1], 0))
      end

      # Add shop hook if NPC owns a shop
      return unless data.include?('shop') && HOOKS[:npc_option2][data['id'].to_i].is_a?(Proc)

      on_npc_option2(data['id'].to_i) do |player, target|
        RuneRb::Shops::ShopManager.open(data['shop'].to_i, player)
        player.interacting_entity = target
      end
    end
  end
end