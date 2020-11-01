module RuneRb::Game::Services
  class MapService
    include Singleton
    include RuneRb::Types::Service

    attr :game_world

    # Called when the map service is created.
    def initialize(world)
      @game_world = world
      @regions = { active: [], inactive: [] }
    end

    def region_for(tile)
      reg = @regions[:active].detect { |region| region.include?(tile[:x], tile[:y]) }
      reg ||= @regions[:active] << RuneRb::Game::Map::Region.from(tile)
    end


    private

    # The logic of the Map
    def execute

    end
  end
end