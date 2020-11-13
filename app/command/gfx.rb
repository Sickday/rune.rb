module RuneRb::Commands
  class Gfx < Command
    def execute(params)
      return unless params[:command].length >= 1

      params[:player].play_graphic(RuneRb::Model::Graphic.new(params[:command][0].to_i,
                                                             params[:command][1].to_i || 100,
                                                             params[:command][2].to_i || 0))
     end
  end
end