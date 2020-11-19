module RuneRb::Entity
  class Mob
    include RuneRb::Entity::Movement

    # @return [Integer] the index of this Mob in the game World
    attr :index

    # @return [Hash] the list of mobs and players local to the Context
    attr :local

    # @return [Object] the definition for the Mob
    attr :definition

    # @return [OpenStruct] update flags for the Mob
    attr :flags

    # @return [OpenStruct] cool downs for the Mob
    attr :cool_downs

    # @return [Hash] statuses of the Mob
    attr :status

    # @return [RuneRb::Map::Position] the Position of the Mob
    attr :position

    # @return [RuneRb::Map::Position] the regional Position of the Mob
    attr :regional

    # @return [Hash] the Movement of the Context.
    attr :movement

    # @return [RuneRb::Game::World] the World the Mob is attached to.
    attr :world

    # Called when a new Mob is created.
    # @param definition [RuneRb::Database::Profile, Hash] a definition object containing information about the Mob
    # @param world [RuneRb::Game::World] the world in which the mob will exist.
    def initialize(world, definition)
      @definition = definition
      @flags = {}
      @cool_downs = OpenStruct.new
      @status = {}
      @local = {}
      @local[:mobs] = []
      @world = world
      @message = OpenStruct.new
      if @definition.is_a? RuneRb::Database::Profile
        setup_movement(@definition.location.to_position)
      else
        setup_movement(@definition[:location])
      end
      init_flags
      update(:local)
    end

    # This function will update the Mob's update flags according to the type and assets provided. Under the hood, this function will enable certain update flags and assign values respectively in accordance with the type of update supplied.
    # For example, if we want to schedule a graphic update, we would pass the type :graphic as well as the actual graphic object (Mob#update(:graphic, gfx: RuneRb::Game::Graphic). Internally, this will enable the Graphic flag causing a flag mask to be added to the sync frame and the client to expect a Graphic block to be supplied in the next pulse.
    # TODO: Raise an error to ensure assets are proper for each schedule type.
    # @param type [Symbol] the type of update to schedule
    # @param assets [Hash] the assets for the update
    def update(type, assets = {})
      case type
      when :local
        @local[:mobs] = @world.local_entities(:mobs, @position)
      when :index
        @index = assets[:index]
      when :movement
        @flags[:moved?] = true
      when :region
        @flags[:region?] = true
      when :state
        @flags[:state?] = true
      when :graphic
        @graphic = assets[:graphic]
        @flags[:graphic?] = true
        @flags[:state?] = true
      when :animation
        @animation = assets[:animation]
        @flags[:animation?] = true
        @flags[:state?] = true
      end
    end

    # Sets the initial state of required update flags.
    def init_flags
      @flags[:state?] = true
      @flags[:teleport?] = true
      @flags[:region?] = true
    end

    # Resets the update flags for the Mob while adhering to exemptions
    # @param exempt [Hash] a collection of flags that are exempt from this reset.
    def reset_flags(exempt)
      @flags[:state?] = exempt[:state?] || false
      @flags[:teleport?] = exempt[:teleport?] || false
      @flags[:region?] = exempt[:region?] || false
      @flags[:forced_chat?] = exempt[:forced_chat?] || false
      @flags[:moved?] = false
    end

    # Reset the status attributes to their default values.
    def reset_status
      @status[:facing] = :EAST
      @status[:busy?] = false
      @status[:dead?] = false
    end
  end
end