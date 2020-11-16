module RuneRb::Entity
  # A Context object is a Mob that is representing the context of a connected Peer session.
  class Context < RuneRb::Entity::Mob
    include RuneRb::Types::Loggable

    # @return [RuneRb::Database::Profile] the Profile of the Context
    attr :profile

    # @return [RuneRb::Database::Appearance] the appearance of the Context
    attr :appearance

    # @return [RuneRb::Game::ItemContainer] the inventory of the Context
    attr :inventory

    # @return [RuneRb::Game::Animation] the Animation of the Context
    attr :animation

    # @return [RuneRb::Game::Graphic] the Graphic of the Context
    attr :graphic

    # @return [OpenStruct] the current message of the Context
    attr :message

    # @return [RuneRb::Game::Equipment] the Equipment of the Context
    attr :equipment

    # @return [RuneRb::Network::Peer] the Peer session for the Context
    attr :session

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Network::Peer] the peer to be associated with the entity.
    # @param profile [RuneRb::Database::Profile] the Profile to be associated wih the entity.
    def initialize(peer, profile)
      @session = peer
      @profile = profile
      @message = OpenStruct.new
      @appearance = @profile.appearance

      setup_inventory
      setup_equipment
      super(@profile.location.to_position)
    end

    # This function will update the Context according to the type and assets provided. Under the hood, this function will enable certain update flags and assign values respectively in accordance with the type of update supplied.
    # For example, if we want to schedule a graphic update, we would pass the type :graphic as well as the actual graphic object (Context#update(:graphic, graphic_object)). Internally, this will enable the Graphic flag causing the client to expect a Graphic to be supplied (and played) during the next pulse.
    # TODO: Raise an error to ensure assets are proper for each schedule type.
    # @param type [Symbol] the type of update to schedule
    # @param assets [Hash] the assets for the update
    def update(type, assets = {})
      super(type, assets)
      case type
      when :skill
        if @profile.stats.level_up?
          level_info = @profile.stats.level_up
          if level_info[:level] == 99
            @session.write_text("Congratulations, you've reached the highest possible #{level_info[:skill]} level of 99!")
          else
            @session.write_text("Congratulations, your #{level_info[:skill]} level is now #{level_info[:level]}!")
          end
        end
        @session.write_skills(@profile.stats)
        @flags[:state?] = true
      when :equipment
        @session.write_equipment(@equipment.data)
        @flags[:state?] = true
      when :inventory
        @session.write_inventory(28, @inventory.data)
      when :chat
        @message[:effects] = assets[:effects]
        @message[:color] = assets[:color]
        @message[:text] = assets[:text]
        @flags[:chat?] = true
      when :teleport
        @flags[:region?] = true
        @flags[:teleport?] = true
      when :morph
        @profile.appearance.to_mob(assets[:mob_id])
        @flags[:state?] = true
      when :overhead
        @profile.appearance.head_to(assets[:head_icon] <= 7 && assets[:head_icon] >= -1 ? assets[:head_icon] : 0)
        @flags[:state?] = true
      else "Unrecognized update type! #{type}"
      end
    end

    # Handles saving and dumping of attributes for the context
    def logout
      RuneRb::Game::Containers::Inventory.dump(self)
      RuneRb::Entity::Equipment.dump(self)
      @profile.location.set(@position)
    end

    # Sets initial update flags for the Context.
    # @param exempt [Hash] the flags exempt from this reset.
    def reset_flags(exempt = {})
      @flags[:chat?] = exempt[:chat?] || false
      @flags[:graphic?] = exempt[:graphic?] || false
      @flags[:animation?] = exempt[:animation?] || false
      super(exempt)
    end

    # @return [String] an inspection of the Context
    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
      str << "[POSITION]: #{@position.inspect}"
    end

    # Certain logic that should occur per pulse or on pulse intervals are observed here. (Movement)
    def pulse
      move
    end

    private

    # Initialize Inventory for the Context. Attempts to load inventory from serialized dump or create a new empty Inventory for the context
    def setup_inventory
      if !@profile[:inventory].nil?
        @inventory = RuneRb::Game::Containers::Inventory.restore(self)
        log(RuneRb::COL.green("Restored Inventory for #{@profile[:name]}")) if RuneRb::DEBUG
      else
        @inventory = RuneRb::Game::Containers::Inventory.new
        log(RuneRb::COL.magenta("New Inventory set for #{@profile[:name]}")) if RuneRb::DEBUG
      end
      @session.write_inventory(28, @inventory.data)
    end

    # Initialize Equipment for the Context. Attempts to load equipment from serialized dump or create a new empty Equipment model for the context.
    def setup_equipment
      if !@profile[:equipment].nil? && !Oj.load(@profile[:equipment]).empty?
        @equipment = RuneRb::Entity::Equipment.restore(self)
        log(RuneRb::COL.green("Restored Equipment for #{@profile[:name]}")) if RuneRb::DEBUG
      else
        @equipment = RuneRb::Entity::Equipment.new
        log(RuneRb::COL.magenta("New Equipment set for #{@profile[:name]}")) if RuneRb::DEBUG
      end
      @session.write_equipment(@equipment.data)
    end
  end
end
