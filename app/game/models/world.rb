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
      load_mob_spawns
      log RuneRb::COL.on_blue('New World instance initialized!')
    rescue StandardError => e
      err! 'A fatal error occurred while initialize World instance!'
      puts e
      puts e.backtrace
    end

    # Schedules a block to be executed by the World#workers
    def schedule(&task)
      @workers.post { task.call }
    rescue StandardError => e
      err 'An error occurred while executing task!'
      puts e
      puts e.backtrace
    end

    # Receives and registers an entity to the world.
    def receive(entity)
      case entity
      when RuneRb::Network::Peer
        ctx = RuneRb::Entity::Context.new(entity, self)
        @entities[:players] << ctx
        ctx.update(:index, index: @entities[:players].index(ctx))
        entity.write_login
        entity.register_context(ctx)
        log RuneRb::COL.on_green("Registered new Context! Welcome, #{entity.profile[:name]}!")
      when RuneRb::Entity::Mob
        @entities[:mobs] << entity
        entity.update(:index, index: @entities[:mobs].index(entity))
        entity.update(:location)
      else
        raise "Unrecognized entity reached reception! #{entity.inspect}"
      end
    rescue StandardError => e
      err 'An error occurred while receiving entity!'
      puts e
      puts e.backtrace
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
      err 'An error occurred while releasing entity!'
      puts e
      puts e.backtrace
    end

    # Fetches a list of local mobs or players to a reference Position
    # @param type [Symbol] the type of entity to fetch
    # @param reference [RuneRb::Map::Position] the position to get local entities for
    def local_entities(type, reference)
      schedule do
        case type
        when :mobs
          @entities[:mobs].select { |mob| mob.position.in_view?(reference) }
        when :players
          @entities[:players].select { |player| player.position.in_view?(reference) }
        else err 'Unrecognized type for local entity request!', type.to_s
        end
      end
    end

    private

    # Loads mob spawns from the database and creates appropriate Mobs for models.
    def load_mob_spawns
      RuneRb::Database::LEGACY[:mob_spawns].all.each do |row|
        definition = {}.tap do |hash|
          hash[:id] = row[:mob_id]
          hash[:location] = RuneRb::Map::Position.new(row[:x], row[:y], row[:z])
          hash[:face] = row[:face]
        end
        mob = RuneRb::Entity::Mob.new(self, definition)
        receive(mob)
      end
    rescue StandardError => e
      puts 'An error occurred while spawning Mobs!'
      puts e
      puts e.backtrace
    end

  end
end