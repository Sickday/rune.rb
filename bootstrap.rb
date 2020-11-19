require_relative 'app/rune'


TEST_WORLD = RuneRb::Game::World.new
ENDPOINT = RuneRb::Network::Endpoint.new(TEST_WORLD)
ENDPOINT.deploy