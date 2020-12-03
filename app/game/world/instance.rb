module RuneRb::World
  # A World Instance object models a virtual game world. The Instance object manages mobs, events, and most of all the game logic processing.
  class Instance
    include RuneRb::Internal::Log
    include LoginHelper
    include CommandHelper

    # @return [Hash] a map of entities the Instance has spawned
    attr :entities

    # Called when a new World Instance is created
    # @param config [Hash] the configuration for the World Instance.
    def initialize(config = {})
      init_config(config)
      init_entities
      init_commands
      log RuneRb::COL.green('New World Instance initialized!')
    end

    # Creates a context mob, adds the mob to the Instance#entities hash, assigns the mob's index, then calls Context#login providing the Instance as the parameter
    # @param session [RuneRb::Net::Session] the session session for the context
    # @param profile [RuneRb::Database::Profile] the profile for the context
    def receive(session, profile)
      ctx = RuneRb::Entity::Context.new(session, profile)
      @entities[:players].tap do |hash|
        ctx.index = hash.empty? ? 1 : hash.keys.last + 1
        @entities[:players][ctx.index] = ctx
      end
      ctx.login(self)
      session.register(ctx)
      log RuneRb::COL.green("Registered new Context for #{RuneRb::COL.yellow(profile.name)}") if RuneRb::DEBUG
      log RuneRb::COL.green("Welcome, #{RuneRb::COL.yellow(profile.name)}!")
      session.status[:auth] = :LOGGED_IN
    rescue StandardError => e
      err 'An error occurred while receiving context!', e
      puts e.backtrace
    end

    # Removes a context mob from the Instance#entities hash, then calls Context#logout on the specified mob to ensure a logout is performed.
    # @param context [RuneRb::Entity::Context] the context mob to release
    def release(context)
      # Remove the context from the entity list
      @entities[:players].delete(context.index)
      # Logout the context.
      context.logout
      log RuneRb::COL.magenta("De-registered Context for #{RuneRb::COL.yellow(context.profile.name)}") if RuneRb::DEBUG
      log RuneRb::COL.magenta("See ya, #{RuneRb::COL.yellow(context.profile.name)}!")
    rescue StandardError => e
      err 'An error occurred while releasing context!', e
      puts e.backtrace
    end

    # Requests actions for the world to perform.
    # @param type [Symbol] the type of request
    # @param params [Hash] the parameters for the request.
    def request(type, params = {})
      case type
      when :local_contexts
        @entities[:players].values.select { |ctx| params[:context].position[:current].in_view?(ctx.position[:current]) }
      when :local_mobs
        @entities[:mobs].values.select { |mob| params[:context].position[:current].in_view?(mob.position[:current]) }
      when :spawn_mob
        @entities[:mobs] << RuneRb::Entity::Mob.new(params[:definition]).teleport(params[:position])
      when :context
        @entities[:players].values.detect { |ctx| ctx.profile.name == params[:name] }
      else err "Unrecognized request type for world Instance! #{type}"
      end
    rescue StandardError => e
      err 'An error occurred while processing request!', e
      puts e.backtrace
    end

    private

    # Initializes and loads configuration settings for the World.
    def init_config(config)
      @settings = { MAX_PLAYERS: config[:max_players], MAX_MOBS: config[:max_mobs] }.freeze
    end

    # Initializes and loads entities collections.
    def init_entities
      @entities = { players: {}, mobs: {} }
    end
  end
end