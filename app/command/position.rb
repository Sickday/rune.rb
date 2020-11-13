module RuneRb::Commands
  # A command to display the current position of the player.
  class Position < Command
    # Executes the Command.
    def execute(params)
      params[:player].io.send_message("You current location is #{params[:player].location.inspect}")
    end
  end
end