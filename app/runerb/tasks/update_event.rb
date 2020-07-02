module RuneRb::Tasks
  class UpdateEvent < RuneRb::Engine::Event
    def initialize
      super(600)
    end

    def execute
      ticks = []
      updates = []
      resets = []

      WORLD.npcs.each do |npc|
        ticks << NPCTickTask.new(npc)
        resets << NPCResetTask.new(npc)
      end

      WORLD.players.each do |p|
        next unless p.index

        ticks << PlayerTickTask.new(p)
        resets << PlayerResetTask.new(p)
        updates << PlayerUpdateTask.new(p)
        updates << NPCUpdateTask.new(p)
      end

      ticks.each { |t| WORLD.submit_task { t.execute } }
      updates.each { |t| WORLD.submit_task { t.execute } }
      resets.each { |t| WORLD.submit_task { t.execute } }
    end
  end
end
