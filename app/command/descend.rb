module RuneRb::Commands
  # Moves the player 1 plane lower
  class Descend < Command
    def execute(params)
      params[:player].teleport(params[:player].location.transform(0, 0, -1))
    end
  end
end