module RuneRb::Game::Entity::Commands
  # A command to display the current position of the player.
  class Position < RuneRb::Game::Entity::Command
    # Executes the Command.
    def execute
      @assets[:context].session.write(:sys_message, message: "You current location is #{@assets[:context].position[:current].inspect}")
    end
  end
end