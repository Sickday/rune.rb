module RuneRb::Entity
  class Type
    include RuneRb::Types::Serializable

    attr :flags, :status, :properties, :tile, :region
    # Status data for the entity
    # @param facing [Symbol] the direction the entity is facing: [:NORTH, :SOUTH, :EAST, :WEST]
    # @param busy [Boolean] the busy status of the entity (true, false)
    # @param cool_downs [OpenStruct] the current cool downs for the entity
    Status = Struct.new(:facing, :busy, :cool_downs, :dead?)

    # Properties for the entity
    # @param idle_anims [Hash] idle animations of the entity [walk: nil, stand: nil]
    # @param current_anim [Integer] the current animation of the entity
    # @param current_graphic [Integer] the current graphic of the entity
    Properties = Struct.new(:idle_anims, :current_anim, :current_graphic)

    # Called when a new Entity is created.
    def initialize(params = {})
      #@flags = { state: StateFlags.new({ tile: true, entity: false }, true, false, false),
      #move: MovementFlags.new(false, false, false) }
      @status = Status.new(:EAST, false, OpenStruct.new, false)
      @properties = Properties.new({ walk: 0x333, stand: 0x368 }, 0x333, nil)
      @tile = RuneRb::Game::Map::Tile.new(params[:x], params[:y], params[:z])
    end

    def inspect
      str = ''
      str << "\n[PROPERTIES]:\n[IDLE_ANIMATIONS]: #{@properties[:idle_anims]}\n[CURRENT_ANIMATION]: #{@properties[:current_anim]}\n[GRAPHIC]: #{@properties[:current_graphic]}\n"
      str << "[STATUS]:\n[FACING]: #{@status[:facing]}\n[BUSY?]: #{@status[:busy]}\n[ACTIVE_COOLDOWNS]: #{@status[:cool_downs]}\n[DEAD?]: #{@status[:dead?]}\n"
      str << "[LOCATION]:\n[TILE]: #{@tile.inspect}\n"
      str
    end
  end
end