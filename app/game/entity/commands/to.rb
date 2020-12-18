module RuneRb::Game::Entity::Commands
  # A command that teleports a player to a specific position.
  class To < RuneRb::Game::Entity::Command
    def execute
      unless @assets[:command].size >= 2
        @assets[:context].session.write(:sys_message, message: "Not enough parameters for to command! Required: 2, Provided: #{@assets[:command].size}")
        return
      end
      position = RuneRb::Game::Map::Position.new(@assets[:command][0].to_i,
                                           @assets[:command][1].to_i,
                                           @assets[:command].length > 2 ? @assets[:command][2].to_i : 0)

      @assets[:context].session.write(:sys_message, message: "Moving to #{position.inspect}...")
      @assets[:context].teleport(position)
    end
  end
end