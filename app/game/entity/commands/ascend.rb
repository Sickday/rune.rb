module RuneRb::Entity::Commands
  # Moves the player 1 plane higher
  class Ascend < RuneRb::Entity::Command
    def execute
      @assets[:context].teleport(@assets[:context].position[:current].move(0, 0, 1))
    end
  end
end