module RuneRb::Entity
  # A Mob object models a mobile model.
  class Mob
    include RuneRb::Internal::Log
    include RuneRb::Entity::Helpers::Movement
    include RuneRb::Entity::Helpers::Flags

    # @return [Object] a definition object contains details about the Mobs properties. TODO: impl mob definitions.
    attr :definition

    # @return [RuneRb::Entity::Animation] the current Animation of the Mob
    attr :animation

    # @return [RuneRb::Entity::Graphic] the current Graphic of the Mob
    attr :graphic

    # @return [RuneRb::Entity::Message] the current Message of the Mob
    attr :message

    # @return [RuneRb::Map::Regional] the regional position for the mob
    attr :regional

    # @return [Integer] the index of the Mob within it's world Instance's mob list.
    attr_accessor :index

    # Called when a new Mob is created.
    # @param definition [Object] the Definition for the mob.
    def initialize(definition)
      register(definition)
      load_flags
      load_movement
    end

    # Called before a pulse is called
    def pre_pulse
      move
    end

    # Called after a pulse call
    def post_pulse
      reset_movement
      reset_flags
    end

    # Registers a definition to the Mob.
    def register(definition)
      load_definition(definition)
    end

    private

    # Initializes certain mob variables from it's definition.
    def load_definition(definition)
      @id = definition.id
      @position = { current: definition.position, previous: definition.position }
      @regional = @position[:current].regional
      @definition = definition
      log RuneRb::COL.green('Loaded Mob definition!') if RuneRb::DEBUG
    end
  end
end