module RuneRb::Entity
  # A Context object is a Mob that is representing the context of a connected Peer session.
  class Context < RuneRb::Entity::Mob
    include RuneRb::Internal::Log
    include RuneRb::Entity::Helpers::Equipment
    include RuneRb::Entity::Helpers::Inventory
    include RuneRb::Entity::Helpers::Button
    include RuneRb::Entity::Helpers::Click
    include RuneRb::Entity::Helpers::Command

    # @return [RuneRb::Database::Appearance] the appearance of the Context
    attr :appearance

    # @return [Hash] the Equipment data for a context.
    attr :equipment

    # @return [Hash] the Inventory data for the Context
    attr :inventory

    # @return [RuneRb::Net::Peer] the Peer session for the Context
    attr :session

    # @return [RuneRb::Database::Profile] the Profile of the Context which acts as it's definition.
    attr :profile

    # @return [RuneRb::World::Instance] the world Instance the Context is registered to.
    attr :world

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Net::Peer] the peer to be associated with the entity.
    # @param profile [RuneRb::Database::Profile] the profile that will act as the definition for the context mob.
    def initialize(peer, profile)
      @session = peer
      @profile = profile
      super(profile)
    end

    # Logs the context out and detaches the context from the Context#world Instance.
    # * detaches the context from the world instance via Context#detach
    # * dumps the Context#inventory[:container]
    # * dumps the Context#equipment
    # * updates the Context#profile#location to the current Context#position
    # * closes the peer session via Context#session#close_connection
    def logout
      dump_inventory
      dump_equipment
      @profile.location.set(@position[:current])
      @session.write(:logout)
      @world = nil
      log 'Detached from World instance!' if RuneRb::DEBUG
    end

    # Logs the context in and attaches the context to a world Instance.
    # * loads the Context#appearance
    # * loads the Context#inventory
    # * loads the Context#equipment
    # * loads the Context#stats
    # * teleports the Context to Context#position
    # * assigns the Context#world
    # @param world [RuneRb::World::Instance] the world to attach to.
    def login(world)
      load_appearance
      load_inventory
      load_equipment
      #load_stats
      teleport(@position[:current])
      @world = world
      log 'Attached to World instance!' if RuneRb::DEBUG
    rescue StandardError => e
      err! 'An error occurred while attaching peer to Endpoint!'
      puts e
      puts e.backtrace
    end

    # @return [String] an inspection of the Context
    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
      str << "[POSITION]: #{@position.inspect}"
    end

    # Initializes Appearance for the Context.
    def load_appearance
      @appearance = @profile.appearance
      update(:state)
    end

    # Initializes Stats for the Context.
    def load_stats
      write(:skill, skill_id: 0, level: data[:attack_level], experience: data[:attack_exp])
      write(:skill, skill_id: 1, level: data[:defence_level], experience: data[:defence_exp])
      write(:skill, skill_id: 2, level: data[:strength_level], experience: data[:strength_exp])
      write(:skill, skill_id: 3, level: data[:hit_points_level], experience: data[:hit_points_exp])
      write(:skill, skill_id: 4, level: data[:range_level], experience: data[:range_exp])
      write(:skill, skill_id: 5, level: data[:prayer_level], experience: data[:prayer_exp])
      write(:skill, skill_id: 6, level: data[:magic_level], experience: data[:magic_exp])
      write(:skill, skill_id: 7, level: data[:cooking_level], experience: data[:cooking_exp])
      write(:skill, skill_id: 8, level: data[:woodcutting_level], experience: data[:woodcutting_exp])
      write(:skill, skill_id: 9, level: data[:fletching_level], experience: data[:fletching_exp])
      write(:skill, skill_id: 10, level: data[:fishing_level], experience: data[:fishing_exp])
      write(:skill, skill_id: 11, level: data[:firemaking_level], experience: data[:firemaking_exp])
      write(:skill, skill_id: 12, level: data[:crafting_level], experience: data[:crafting_exp])
      write(:skill, skill_id: 13, level: data[:smithing_level], experience: data[:smithing_exp])
      write(:skill, skill_id: 14, level: data[:mining_level], experience: data[:mining_exp])
      write(:skill, skill_id: 15, level: data[:herblore_level], experience: data[:herblore_exp])
      write(:skill, skill_id: 16, level: data[:agility_level], experience: data[:agility_exp])
      write(:skill, skill_id: 17, level: data[:thieving_level], experience: data[:thieving_exp])
      write(:skill, skill_id: 18, level: data[:slayer_level], experience: data[:slayer_exp])
      write(:skill, skill_id: 19, level: data[:farming_level], experience: data[:farming_exp])
      write(:skill, skill_id: 20, level: data[:runecrafting_level], experience: data[:runecrafting_exp])
    end
  end
end
