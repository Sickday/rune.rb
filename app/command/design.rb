module RuneRb::Commands
  # A Command to dispatch the Character Design interface to the player.
  class Design < Command
    def execute(params)
      params[:player].io.send_interface(3559)
    end
  end
end