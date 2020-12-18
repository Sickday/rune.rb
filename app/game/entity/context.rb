module RuneRb::Game::Entity
  # A Context object is a Mob that is representing the context of a connected Session.
  class Context < RuneRb::Game::Entity::Mob
    include RuneRb::System::Log
    include RuneRb::Game::Entity::Helpers::Equipment
    include RuneRb::Game::Entity::Helpers::Inventory
    include RuneRb::Game::Entity::Helpers::Button
    include RuneRb::Game::Entity::Helpers::Click
    include RuneRb::Game::Entity::Helpers::Command

    # @return [RuneRb::System::Database::Appearance] the appearance of the Context
    attr :appearance

    # @return [Hash] the Equipment data for a context.
    attr :equipment

    # @return [Hash] the Inventory data for the Context
    attr :inventory

    # @return [RuneRb::Network::Session] the Session for the Context
    attr :session

    # @return [RuneRb::System::Database::Profile] the Profile of the Context which acts as it's definition.
    attr :profile

    # @return [RuneRb::Game::World::Instance] the world Instance the Context is registered to.
    attr :world

    # Called when a new Context Entity is created.
    # @param session [RuneRb::Network::Session] the session to be associated with the entity.
    # @param profile [RuneRb::System::Database::Profile] the profile that will act as the definition for the context mob.
    def initialize(session, profile)
      @session = session
      @profile = profile
      super(profile)
    end

    # Logs the context out and detaches the context from the Context#world Instance.
    # * detaches the context from the world instance via Context#detach
    # * dumps the Context#inventory[:container]
    # * dumps the Context#equipment
    # * updates the Context#profile#location to the current Context#position
    # * closes the session via Context#session#close_connection
    def logout
      dump_inventory
      dump_equipment
      @profile.location.set(@position[:current])
      @session.write(:logout)
      @world = nil
      log 'Detached from World instance!' if RuneRb::GLOBAL[:RRB_DEBUG]
    end

    # Logs the context in and attaches the context to a world Instance.
    # * loads the Context#appearance
    # * loads the Context#inventory
    # * loads the Context#equipment
    # * loads the Context#stats
    # * teleports the Context to Context#position
    # * assigns the Context#world
    # @param world [RuneRb::Game::World::Instance] the world to attach to.
    def login(world)
      load_appearance
      load_inventory
      load_equipment
      load_commands
      load_stats
      teleport(@position[:current])
      @world = world
      log 'Attached to World instance!' if RuneRb::GLOBAL[:RRB_DEBUG]
    rescue StandardError => e
      err! 'An error occurred while attaching session to Endpoint!'
      puts e
      puts e.backtrace
    end

    # @return [String] an inspection of the Context
    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
      str << "[POSITION]: #{@position.inspect}"
    end

    def pulse
      @session.write(:sync, context: self) if @session.status[:auth] == :LOGGED_IN && @session.status[:active] && @world
    end

    # Initializes Appearance for the Context.
    def load_appearance
      @appearance = @profile.appearance
      update(:state)
    end

    # Initializes Stats for the Context.
    def load_stats
      @stats = @profile.stats
      @session.write(:stats, @stats)
    end
  end
end
