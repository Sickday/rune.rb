
# Logout
on_int_button(2458) { |player| player.io.send_logout }

##
# ::objspawn parameters command.
# Spawns an object with the supplied parameters.
on_command('objspawn') do |player, params|
  temp_loc = player.location
  object = RuneRb::Objects::Object.new(params[0].to_i, temp_loc, 2, params[1].to_i, -1, temp_loc, 0, params[2].to_i)
  object.change

  # Add this to the object manager
  WORLD.object_manager.objects << object
end
##
# ::pos command.
# Sends the context players position.
on_command('pos') { |player, _| player.io.send_message("You are at #{player.location.inspect}.") }
##
# Schedules an update event with the WORLD.
# ::update time
on_command('update') do |_player, params|
  time = params.first.to_i
  WORLD.submit_event(RuneRb::Tasks::SystemUpdateEvent.new(time))
end
##
# ::dc playername
# Forcibly disconnects a player.
on_command('dc') { |player, _params| player.connection.close_connection }
##
# ::goup
# Teleports the player to 1 height level above their current position.
on_command('goup') { |player, _params| player.teleport_location = player.location.transform(0, 0, 1) }
##
# ::godown
# Teleports the player to 1 height level below their current position.
on_command('godown') { |player, _params| player.teleport_location = player.location.transform(0, 0, -1) }
##
# ::item params
# Spawns an item given it's id and count.
on_command('item') do |player, params|
  id = params[0].to_i
  count = params.length == 2 ? params[1].to_i : 1
  player.inventory.add RuneRb::Item::Item.new(id, count)
end
##
# ::design
# Opens the makeover interface
on_command('design') { |player, _params| player.io.send_interface(3559) }
##
# ::reload
# Reloads the server
on_command('reload') do |player, _params|
  player.io.send_message 'Reloading...'
  SERVER.reload
end
##
# ::spawn parameters
# Spawns an npc given it's ID.
on_command('spawn') do |player, params|
  id = params[0].to_i
  npc = RuneRb::NPC::NPC.new RuneRb::NPC::NPCDefinition.for_id(id)
  npc.location = player.location.transform(1, 1, 0)

  WORLD.register_npc(npc)
end
##
# ::cfg parameters
# Sets the configuration given it's ID and the value to set it to.
on_command('cfg') do |player, params|
  id = params[0].to_i
  value = params[1].to_i
  player.io.send_config(id, value)
  player.io.send_message("Setting #{id} to #{value}")
end
##
# ::teleto parameters
# Attempts to teleport to a player given their name.
on_command('teleto') do |player, params|
  target = get_player(params[0])
  if target.nil?
    player.io.send_message('User not found.')
  else
    player.teleport_location = target.location
    player.io.send_message("You were teleported to #{target.name}.")
    target.io.send_message("#{player.name} teleported to you.")
  end
end
##
# ::guess parameters
# A simple guessing game to test rng? The player will get a message if they successfully guess the same number we generate.
on_command('guess') do |player, params|
  # Turn the string into an integer using to_i
  number = params[0].to_i

  if number == rand(256)
    player.io.send_message('Yay! You win!')
  else
    player.io.send_message('You guessed wrong!')
  end
end
##
# ::tele parameters
# Teleports the player to the supplied coordinates
on_command('tele') do |player, params|
  x = params[0].to_i
  y = params[1].to_i
  z = params.length > 2 ? params[2].to_i : 0
  loc = RuneRb::Model::Location.new(x, y, z)
  player.io.send_message "Teleporting to #{loc.inspect}..."
  player.teleport_location = loc
end
##
# ::snow
# Starts the snow effect.
on_command('snow') { |player, _params| player.io.send_interface(11_877, true) }
##
# ::teletome
# Attempts to teleport the specified player to the context player.
on_command('teletome') do |player, params|
  target = get_player(params[0])
  if target.nil?
    player.io.send_message('User not found.')
  else
    target.teleport_location = player.location
    player.io.send_message("#{target.name} was teleported to you.")
    target.io.send_message("You were teleported to #{player.name}.")
  end
end
##
# ::teleall
# Attempts to teleport all players in the world to the context player.
on_command('teleall') do |player, _params|
  WORLD.players.each do |target|
    if !target.nil? && (target.name != player.name)
      target.teleport_location = player.location
      target.io.send_message("You were teleported to #{player.name}.")
    end
  end
end
##
# ::move
# Toggles the forced_move flag for the context player.
on_command('move') { |player, _params| player.flags.flag(:forced_move) }
##
# ::em parameter
# Returns the value of a player object's variable with the same name as the first parameter.
# TODO: Unsafe use of Kernel#eval should be removed.
on_command('em') do |player, params|
  val = eval("player.#{params.first}")
  player.io.send_message "returned: #{val.inspect}"
end
##
# ::g
# Forces the player to face East.
on_command('g') do |player, _params|
  x = player.location.x + 1
  y = player.location.y
  z = player.location.z

  player.face(RuneRb::Model::Location.new(x, y, z))
end
##
# ::max
# Maxes out the player's stats.
on_command('max') do |player, _params|
  RuneRb::Player::Skills::SKILLS.each do |skill|
    player.skills.set_skill(skill, 99, 13_034_431)
  end
  player.flags.flag(:appearance)
end
##
# ::md parameter
# Sets the context player's model to the supplied id
on_command('md') do |player, params|
  player.model = params.first.to_i
  player.flags.flag :appearance
end
##
# ::sa parameter
# Sets the context player's standing animation to the supplied id.
on_command('sa') do |player, params|
  player.standanim = params.first.to_i
  player.flags.flag :appearance
end
##
# ::wa parameter
# Sets the context player's walking animation to the supplied id.
on_command('wa') do |player, params|
  player.walkanim = params.first.to_i
  player.flags.flag :appearance
end
##
# ::empty
# Clears the context player's inventory.
on_command('empty') do |player, _params|
  player.inventory.clear
  player.inventory.fire_items_changed
end
##
# ::bank
# Opens the bank interface (and adds random ass items to the container for some reason.)
on_command("bank") do |player, _params|
  21.times { player.bank.add(RuneRb::Item::Item.new(rand(1040...1056))) }
  Bank.open(player)
end
##
# Attmpts to retreived a player given their name. 
# TODO: rename this function and perhaps move it to the WORLD object?
# `WORLD#by_name(name) seems cleaner`
def self.get_player(name)
  WORLD.players.find { |e| e.name.downcase == name.downcase }
end

{161 => 860,
 162 => 857,
 163 => 863,
 164 => 858,
 165 => 859,
 166 => 866,
 167 => 864,
 168 => 855,
 169 => 856,
 170 => 861,
 171 => 862,
 172 => 865,
 13_362 => 2105,
 13_363 => 2106,
 13_364 => 2107,
 13_365 => 2108,
 13_366 => 2109,
 13_367 => 2110,
 13_368 => 2111,
 13_383 => 2127,
 13_384 => 2128,
 13_369 => 2112,
 13_370 => 2113,
 11_100 => 1368,
 667 => 1131,
 6503 => 1130,
 6506 => 1129,
 666 => 1128}.each do |button, anim|
  on_int_button(button) { |player| player.play_animation(RuneRb::Model::Animation.new(anim)) }
end
=begin
on_item_on_player(1050) do |player, used_player|
  player.io.send_message('You used 1050 on a player')
  used_player.io.send_message('someone used 1050 on you')
end

on_item_on_npc(1050, 1) do |player, _npc|
  player.io.send_message 'You used a santa on an npc'
end

on_int_button(3651) do |player|
  player.io.send_clear_screen
end
on_npc_option2(592) do |player, _npc|
  player.io.send_message 'Open shop'
end=end
