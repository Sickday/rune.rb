RUNES ||= {}

XmlSimple.xml_in('data/magic_runes.xml', 'KeyToSymbol' => true)[:rune].each do |data|
  name = data['name'].to_sym
  id = data['id'].to_i
  staves = data.include?(:staff) ? data[:staff].collect { |v| v['id'].to_i } : []
  parts = data.include?(:part) ? data[:part].collect { |v| v['name'].to_sym } : []
  RUNES[name] = {id: id, staves: staves}
  RUNES[name][:parts] = parts unless parts.empty?
end

def cast_spell(req, player)
  req.default = 0
  remaining = req.dup
  # Staffs
  req.each do |rune, amount|
    remaining[rune] -= amount if RUNES[rune][:staves].any? { |item| player.equipment.contains(item) }
  end
  # Combination runes
  _combinations = RUNES.find_all do |k, v|
    if v.include?(:parts)
      v[:parts].each { |part| remaining[part] -= 1 if player.inventory.contains(RUNES[k][:id]) }
    end
  end
  # Standard runes
  req.each { |rune, amount| remaining[rune] -= amount if player.inventory.count(RUNES[rune][:id]) >= amount }
  player.io.send_message('You do not have the required runes to cast this spell.') if remaining.values.any?(&:positive?)
end

def projectile(src, dest, angle, speed, id, start_z, end_z, index)
  offset = RuneRb::Model::Location.new(-(src.x - dest.x), -(src.x - dest.y), 0)

  WORLD.region_manager.get_local_players(src).each do |p|
    next unless p&.location&.within_distance?(src)

    # Region
    region = RuneRb::Net::PacketBuilder.new(85)
                 .add_byte_c(src.get_local_y(p.last_location) - 2)
                 .add_byte_c(src.get_local_x(p.last_location) - 3)
                 .to_packet
    # Graphic
    graphic = RuneRb::Net::PacketBuilder.new(117)
                  .add_byte(angle)
                  .add_byte(offset.y)
                  .add_byte(offset.x)
                  .add_short(index + 1)
                  .add_short(id)
                  .add_byte(start_z)
                  .add_byte(end_z)
                  .add_short(50 + 12)
                  .add_short(speed)
                  .add_byte(16)
                  .add_byte(64)
                  .to_packet
    p.connection.send_data(region)
    p.connection.send_data(graphic)
  end
end

def stillgfx(id, x, y, z)
  loc = RuneRb::Model::Location.new(x, y, z)

  WORLD.region_manager.get_local_players(loc).each do |p|
    next unless p&.location&.within_distance?(loc)

    # Region
    region = RuneRb::Net::PacketBuilder.new(85)
                 .add_byte_c(loc.get_local_y(p.last_location))
                 .add_byte_c(loc.get_local_x(p.last_location))
                 .to_packet
    # Graphic
    graphic = RuneRb::Net::PacketBuilder.new(4)
                  .add_byte(0) # Tiles away = (X >> 4 + Y & 7)
                  .add_short(id) # Graphic ID
                  .add_byte(80) # Height
                  .add_short(14) # Time before casting the graphic
                  .to_packet

    p.connection.send_data(region) # Region Update first
    p.connection.send_data(graphic) # Graphic update next.
  end
end

on_magic_on_npc(1152) { |player, _npc| cast_spell({air: 1, mind: 1}, player) }

on_magic_on_npc(1183) do |player, npc|
  player.walking_queue.reset
  player.interacting_entity = npc
  player.walking_queue.reset

  player.play_graphic RuneRb::Model::Graphic.new(158, 6_553_600)
  player.play_animation RuneRb::Model::Animation.new(711)

  projectile(player.location, npc.location, 50, 90, 159, 40, 40, npc.index)
end