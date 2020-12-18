module RuneRb::Game::Entity::Commands
  # A Command to spawn items for the player.
  class Item < RuneRb::Game::Entity::Command
    def execute
      unless @assets[:command].size >= 2
        @assets[:context].session.write(:sys_message, message: "Not enough parameters for this command! Required: 2 or more, Provided: #{@assets[:command].size}")
        return
      end
      stack = RuneRb::Game::Item::Stack.new(@assets[:command][0].to_i)
      if stack.definition[:stackable]
        stack.size = @assets[:command][1].to_i
        @assets[:context].inventory[:container].add(stack)
        log RuneRb::COL.green("Adding #{stack.definition[:name]} x #{stack.size}") if RuneRb::GLOBAL[:RRB_DEBUG]
      else
        @assets[:command][1].to_i.times do
          @assets[:context].inventory[:container].add(stack)
          log RuneRb::COL.green("Adding #{stack.definition[:name]} x #{stack.size}") if RuneRb::GLOBAL[:RRB_DEBUG]
        end
      end
      @assets[:context].update(:inventory)
    end
  end
end