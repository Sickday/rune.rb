module RuneRb::Commands
  class Update < Command
    def execute(params)
      unless params[:command].size >= 1
        params[:player].io.send_message("Not enough parameters for this command! Required: 1, Provided: #{params[:command].size}")
        return
      end
      time = params[:command].first.to_i
      puts "Scheduling update for #{time}"
      params[:world].submit_event(RuneRb::Tasks::SystemUpdateEvent.new(time))
    end
  end
end