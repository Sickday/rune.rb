module RuneRb::Commands
  class GameObject < Command
    def execute(params)
      temp_loc = params[:player].location
      # TODO: Holy shit refactor this wtf.
      object = RuneRb::Objects::Object.new(params[:command][0].to_i,
                                          temp_loc,
                                          2,
                                          params[:command][1].to_i,
                                          -1,
                                          temp_loc,
                                          0,
                                          params[:command][2].to_i).change
      # Add this to the object manager
      params[:world].object_manager.objects << object
    end
  end
end