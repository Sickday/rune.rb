module RuneRb::Commands
  class Anim < Command
    def execute(params)
      return unless params[:command].length >= 1

      params[:player].schedule(:animation, animation: RuneRb::Game::Animation.new(params[:command][0].to_i,
                                                                                  params[:command][1].to_i || 0))
    end
  end
end