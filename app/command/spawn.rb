module RuneRb::Commands
  # A command to spawn Mobs in a location relative to the player.
  class Spawn < Command
    def execute(params)
      unless params[:command].size >= 1
        params[:player].io.send_message("Not enough parameters for this command! Required: 2, Provided: #{params[:command].size}")
        return
      end
      id = params[:command][0].to_i
      npc = RuneRb::NPC::NPC.new RuneRb::NPC::NPCDefinition.for_id(id)
      npc.location = params[:player].location.transform(1, 1, 0)
      params[:world].register_npc(npc)
      params[:player].io.send_message("Spawned NPC #{id} @ #{npc.location.inspect}!")
    end
  end
end