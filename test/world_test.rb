require_relative '../app/rune'

party_3 = RuneRb::Game::World.new
plr = RuneRb::Entity::Context.new

rand(256).times { party_3.receive([RuneRb::Entity::Context.new, RuneRb::Entity::Mob.new].sample) }
party_3.receive(plr)
puts party_3.inspect
