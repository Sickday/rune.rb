# Just missing level checks for things. Otherwise working.
# Could use some clean-up
# Basically the same code except for: # of fire runes, XP, item cost, anim, and graphic

# Low alch
on_magic_on_item(1162) do |player, id, slot|
  fire_staff = [1387, 3053, 3055].any? { |item| player.equipment.contains(item) }
  if (fire_staff || player.inventory.count(554) >= 3) && player.inventory.contains(561)
    if id == 995
      player.io.send_message('You cannot turn gold into gold!')
      next
    end

    item = RuneRb::Item::Item.new(id, 1)

    player.inventory.remove(-1, RuneRb::Item::Item.new(554, 3)) unless fire_staff
    player.inventory.remove(-1, RuneRb::Item::Item.new(561, 1))
    player.inventory.remove(slot, item)
    player.inventory.add(RuneRb::Item::Item.new(995, item.definition.lowalc))
    player.skills.add_exp(:magic, 31)
    player.play_animation(RuneRb::World::Animation.new(712))
    player.play_graphic(RuneRb::World::Graphic.new(112, 2))
  else
    player.io.send_message('You do not have the required runes to cast this spell.')
  end
end

# High alch
on_magic_on_item(1178) do |player, id, slot|
  fire_staff = [1387, 3053, 3055].any? { |item| player.equipment.contains(item) }
  if (fire_staff || player.inventory.count(554) >= 5) && player.inventory.contains(561)
    if id == 995
      player.io.send_message('You cannot turn gold into gold!')
      next
    end

    item = RuneRb::Item::Item.new(id, 1)
    player.inventory.remove(-1, RuneRb::Item::Item.new(554, 5)) unless fire_staff
    player.inventory.remove(-1, RuneRb::Item::Item.new(561, 1))
    player.inventory.remove(slot, item)
    player.inventory.add(RuneRb::Item::Item.new(995, item.definition.highalc))
    player.skills.add_exp(:magic, 65)
    player.play_animation(RuneRb::World::Animation.new(713))
    player.play_graphic(RuneRb::World::Graphic.new(113, 2))
  else
    player.io.send_message 'You do not have the required runes to cast this spell.'
  end
end