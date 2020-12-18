module RuneRb::Game::Entity::Commands
  # Moves the player 1 plane lower
  class Descend < RuneRb::Game::Entity::Command
    def execute
      @assets[:context].teleport(@assets[:context].position[:current].move(0, 0, -1))
    end
  end
end