module RuneRb::Commands
  # A command that teleports a player to a specific position.
  class To < Command
    def execute(params)
      unless params[:command].size >= 2
        params[:player].io.send_message("Not enough parameters for to command! Required: 2, Provided: #{params[:command].size}")
        return
      end

      loc = RuneRb::Model::Location.new(params[:command][0].to_i,
                                       params[:command][1].to_i,
                                       params[:command].length > 2 ? params[:command][2].to_i : 0)
      params[:player].io.send_message("Moving to #{loc.inspect}...")
      params[:player].teleport(loc)
    end
  end
end