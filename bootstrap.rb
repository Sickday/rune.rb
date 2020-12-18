require_relative 'app/rune.rb'

RuneRb::Network::Endpoint.new(world: RuneRb::Game::World::Instance.new).run