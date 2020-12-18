require_relative '../app/rune'

RuneRb::Network::Endpoint.new(world: RuneRb::Game::World::Instance.new).run