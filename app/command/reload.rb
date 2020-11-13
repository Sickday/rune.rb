module RuneRb::Commands
  class Reload < Command
    def execute(params)
      params[:player].io.send_message 'Reloading...'
      SERVER.reload
    end
  end
end