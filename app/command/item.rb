module RuneRb::Commands
  # A Command to spawn items for the player.
  class Item < Command
    def execute(params)
      unless params[:command].size >= 2
                               params[:player].io.send_message("Not enough parameters for this command! Required: 2 or more, Provided: #{params[:command].size}")
                               return
                             end
      stack = RuneRb::Game::ItemStack.new(params[:command][0].to_i)
      if stack.definition[:stackable]
        stack.size = params[:command][2].to_i
        params[:player].inventory.add(stack)
        log RuneRb::COL.green("Adding #{stack.definition[:name]} x #{stack.size}") if RuneRb::DEBUG
      else
        params[:command][2].to_i.times do
          params[:player].inventory.add(stack)
          log RuneRb::COL.green("Adding #{stack.definition[:name]} x #{stack.size}") if RuneRb::DEBUG
        end
      end
      @context.update_inventory
    end
  end
end