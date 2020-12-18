module RuneRb::Game::Entity::Commands
  class Morph < RuneRb::Game::Entity::Command
    def execute
      @assets[:context].update(:morph, mob_id: @assets[:command][0].to_i)
    end
  end
end