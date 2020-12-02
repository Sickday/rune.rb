module RuneRb::World::Commands
  # A Command to dispatch the Character Design interface to the player.
  class Design < RuneRb::World::Command
    def execute
      @assets[:context].session.write(:interface, id: 3559)
    end
  end
end