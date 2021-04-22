module RuneRb::Game::World::Synchronization

  def start_sync_service
    EventMachine.add_periodic_timer(0.600) do
      unless @entities[:players].empty? && @entities[:mobs].empty?
        prepare_sync
        sync
        complete_sync
      end
    end
  end

  private

  def prepare_sync
    post(id: :SYNC_PREPARATION, priority: :HIGH, assets: [@entities[:mobs], @entities[:players]]) do |mobs, players|
      # Complete pre-sync work for mobs
      mobs.each_value(&:pre_sync)

      # Complete pre-sync work for players.
      players.each_value(&:pre_sync)
    end
  end

  def sync
    post(id: :SYNC, priority: :MEDIUM, assets: [@entities[:mobs], @entities[:players]]) do |mobs, players|
      # Complete synchronization for each player
      players.each_value(&:sync)

      # Complete synchronization for each mob
      mobs.each_value(&:sync)
    end
  end

  def complete_sync
    post(id: :SYNC_COMPLETE, priority: :LOW, assets: [@entities[:mobs], @entities[:players]]) do |mobs, players|
      # Complete pre-pulse work for mobs
      mobs.each_value(&:post_sync)

      # Complete pre-pulse work for players.
      players.each_value(&:post_sync)
    end
  end
end