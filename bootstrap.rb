require_relative 'app/rune'

TEST_WORLD = RuneRb::World::Instance.new
ENDPOINT = RuneRb::Net::Endpoint.new(TEST_WORLD)
ENDPOINT.deploy