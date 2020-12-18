module RuneRb::Game::World
  # A World Instance object models a virtual game world. The Instance object manages mobs, events, and most of all the game logic processing.
  class Instance
    using RuneRb::System::Patches::SetOverrides

    include RuneRb::System::Log
    include LoginHelper

    # @return [Hash] a map of entities the Instance has spawned
    attr :entities

    # Called when a new World Instance is created
    # @param config [Hash] the configuration for the World Instance.
    def initialize(config = {})
      init_config(config)
      init_entities
      init_pulse
      log 'New World Instance initialized!'
    end

    # When a job (Proc/Lambda) is passed, work will be scheduled to be executed via a Concurrent::Promise.
    # This object does not guarantee any specific executing time other than 'some time in the future', this it's name 'Promise'.
    # @param job [Proc] the job to schedule.
    def schedule(&job)
      raise 'Invalid job scheduled!' unless block_given?

      Concurrent::Promise.execute { job.call }
    rescue StandardError => e
      err 'An error occurred while scheduling job!', e
      puts e.backtrace
    end

    # Creates a context mob, adds the mob to the Instance#entities hash, assigns the mob's index, then calls Context#login providing the Instance as the parameter
    # @param session [RuneRb::Net::Session] the session session for the context
    # @param profile [RuneRb::System::Database::Profile] the profile for the context
    def receive(session, profile)
      schedule do
        ctx = RuneRb::Game::Entity::Context.new(session, profile)
        @entities[:players].tap do |hash|
          ctx.index = hash.empty? ? 1 : hash.keys.last + 1
          @entities[:players][ctx.index] = ctx
        end
        ctx.login(self)
        session.register(ctx)
        log RuneRb::COL.green("Registered new Context for #{RuneRb::COL.yellow(profile[:name].capitalize)}") if RuneRb::GLOBAL[:RRB_DEBUG]
        log RuneRb::COL.green("Welcome, #{RuneRb::COL.yellow.bold(profile[:name].capitalize)}!")
        session.status[:auth] = :LOGGED_IN
      end
    rescue StandardError => e
      err 'An error occurred while receiving context!', e
      puts e.backtrace
    end

    # Removes a context mob from the Instance#entities hash, then calls Context#logout on the specified mob to ensure a logout is performed.
    # @param context [RuneRb::Game::Entity::Context] the context mob to release
    def release(context)
      return unless context

      schedule do
        # Remove the context from the entity list
        @entities[:players].delete(context.index)
        # Logout the context.
        context.logout
        log RuneRb::COL.magenta("De-registered Context for #{RuneRb::COL.yellow(context.profile[:name].capitalize)}") if RuneRb::GLOBAL[:RRB_DEBUG]
        log RuneRb::COL.magenta("See ya, #{RuneRb::COL.yellow(context.profile[:name].capitalize)}!")
      end
    rescue StandardError => e
      err 'An error occurred while releasing context!', e
      puts e.backtrace
    end

    # Requests actions for the world to perform.
    # @param type [Symbol] the type of request
    # @param params [Hash] the parameters for the request.
    def request(type, params = {})
      schedule do
        case type
        when :local_contexts
          @entities[:players].values.select { |ctx| params[:context].position[:current].in_view?(ctx.position[:current]) }
        when :local_mobs
          @entities[:mobs].values.select { |mob| params[:context].position[:current].in_view?(mob.position[:current]) }
        when :spawn_mob
          @entities[:mobs] << RuneRb::Game::Entity::Mob.new(params[:definition]).teleport(params[:position])
        when :context
          @entities[:players].values.detect { |ctx| ctx.profile.name == params[:name] }
        else err "Unrecognized request type for world Instance! #{type}"
        end
      end.value
    rescue StandardError => e
      err 'An error occurred while processing request!', e
      puts e.backtrace
    end

    def inspect
      log RuneRb::COL.green("[Title]: #{RuneRb::COL.yellow.bold(@settings[:LABEL])}")
      log RuneRb::COL.green("[Players]: #{RuneRb::COL.yellow.bold(@entities[:players].size)}/#{@settings[:MAX_PLAYERS]}]")
      log RuneRb::COL.green("[Mobs]: #{RuneRb::COL.yellow.bold(@entities[:mobs].size)}/#{@settings[:MAX_MOBS]}]")
    end

    # Pulse the player entities of the world instance.
    def pulse
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @entities[:players].values.each do |context|
        context.pre_pulse
        context.pulse
        context.post_pulse
      end
    rescue StandardError => e
      err 'An error occurred pulsing entities!', e
      puts e.backtrace
    ensure
      log "Pulse completed in #{RuneRb::COL.yellow.bold((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(3))} seconds" if RuneRb::GLOBAL[:RRB_DEBUG]
    end

    private

    # Initializes and loads configuration settings for the World.
    def init_config(config)
      @settings = { LABEL: config[:label] || 'TEST_WORLD', MAX_PLAYERS: config[:max_players] || 2000, MAX_MOBS: config[:max_mobs] || 10_000 }.freeze
    end

    # Initializes and loads entities collections.
    def init_entities
      @entities = { players: {}, mobs: {} }
    end

    def init_pulse
      @pulse = Concurrent::TimerTask.execute(execution_interval: 0.600) { @entities[:players].empty? ? return : pulse }
    end
  end
end