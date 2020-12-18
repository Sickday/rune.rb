module RuneRb::Game::Entity::Commands
  class Graphic < RuneRb::Game::Entity::Command
    def execute
      return unless @assets[:command].length >= 1

      @assets[:context].update(:graphic, RuneRb::Game::Entity::Graphic.new(@assets[:command][0].to_i,
                                                                     @assets[:command][1].to_i || 100,
                                                                     @assets[:command][2].to_i || 0))
    end
  end
end