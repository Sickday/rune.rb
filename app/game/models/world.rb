module RuneRb::Game
  # A World object manages the logic and management of context mobs, items, and objects
  class World
    include RuneRb::Types::Loggable

    # @return [Hash] a collection of player contexts and mobs.
    attr :entities

    # Called when a new World is created.
    def initialize
      @entities = { players: [], mobs: [] }
      @workers = Concurrent::CachedThreadPool.new(max_threads: Concurrent.processor_count, min_threads: Concurrent.processor_count)
      log RuneRb::COL.on_blue('New World instance initialized!')
    rescue StandardError => e
      err! 'A fatal error occurred while initialize World instance!', e, e.backtrace
    end

    # Schedules a block to be executed by the World#workers
    def schedule(&task)
      @workers.post { task.call }
    rescue StandardError => e
      err 'An error occurred while executing task!', e, e.backtrace
    end

    # Receives and registers an entity to the world.
    def receive(entity)
      case entity
      when RuneRb::Network::Peer
        ctx = RuneRb::Entity::Context.new(entity, self)
        @entities[:players] << ctx
        entity.write_login
        entity.register_context(ctx)
        log RuneRb::COL.on_green("Registered new Context! Welcome, #{entity.profile[:name]}!")
      when Hash
        # TODO: create a mob instance from the data hash
        # @entities[:mobs] << entity
      else
        raise "Unrecognized entity reached reception! #{entity.inspect}"
      end
    rescue StandardError => e
      err 'An error occurred while receiving entity!', entity.inspect, e, e.backtrace
    end

    # Releases and unregisters entity from the World
    # @param entity [RuneRb::Entity::Mob] the entity to release.
    def release(entity)
      case entity
      when RuneRb::Entity::Context
        @entities[:players].delete(entity)
        log RuneRb::COL.on_magenta("Released context. Good-bye, #{entity.profile[:name]}!")
      when RuneRb::Entity::Mob
        @entities[:mobs].delete(entity)
      else
        raise "Unrecognized entity release! #{entity.inspect}"
      end
    rescue StandardError => e
      err 'An error occurred while releasing entity!', entity.inspect, e, e.backtrace
    end
  end
end