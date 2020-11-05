module RuneRb::Game::Services
  # A object designed to ensure entities and mobs are in sync with the RuneRb::Game::World.
  class SyncService

    # Called when a new Synchronization object is created.
    def initialize
      @executor = Concurrent::FixedThreadPool.new(Concurrent.physical_processor_count)
      @barrier = Concurrent::CycilicBarrier.new(@executor.min_length)
    end

    # A pulse generates updates for entities and then dispatches them.
    def pulse(players, mobs)
      players.each do |player|
        # Wait for any threads still working. We want them all to start at the same time.
        @barrier.wait
        execute { }
      end

      mobs.each do |mob|

      end
    end

    def execute(&task)
      @executor.post do
        task.call
        @barrier.wait
      end
    end
  end
end