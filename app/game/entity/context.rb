module RuneRb::Entity
  class Context < RuneRb::Entity::Type
    include RuneRb::Types::Loggable

    # @return [RuneRb::Game::Map::Position] the Position of the Context
    attr :position

    # @return [RuneRb::Game::Map::Position] the regional Position of the Context
    attr :region

    # @return [Hash] the movement of the Context.
    attr :movement

    # @return [RuneRb::Database::Profile] the Profile of the Context
    attr :profile

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

    # @return [RuneRb::Network::Peer] the Peer for the Context
    attr :session

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Network::Peer] the peer to be associated with the entity.
    # @param profile [RuneRb::Database::Profile] the Profile to be associated wih the entity.
    def initialize(peer, profile)
      super()
      @session = peer
      @profile = profile
      @position = profile.location.position
      @message = OpenStruct.new
      @flags = OpenStruct.new
      @movement = { primary_dir: -1,
                    secondary_dir: -1,
                    teleport: { to: @position },
                    handler: RuneRb::Game::Map::Movement.new(self) }
      load_inventory
      load_equipment
      update_region
      init_flags
    end

    # Sets initial update flags for the Context.
    def init_flags
      @flags[:state?] = true
      @flags[:teleport?] = true
      @flags[:region?] = true
    end

    # This function will update the Context according to the type and assets provided. Under the hood, this function will enable certain update flags and assign values respectively in accordance with the type of update supplied.
    # For example, if we want to schedule a graphic update, we would pass the type :graphic as well as the actual graphic object (Context#schedule(:graphic, graphic_object)). Internally, this will enable the Graphic flag causing the client to expect a Graphic to be supplied (and played) during the next pulse.
    # TODO: Raise an error to ensure assets are proper for each schedule type.
    def schedule(type, assets = {})
      case type
      when :move
        @movement[:handler].process
        @flags[:moved?] = true
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
      when :region
        @flags[:region?] = true
      when :state
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
        @profile.location.set(assets[:location])
        @position = @profile.location.position
        @flags[:region?] = true
        @flags[:teleport?] = true
      when :graphic
        @graphic = assets[:graphic]
        @flags[:graphic?] = true
        @flags[:state?] = true
      when :animation
        @animation = assets[:animation]
        @flags[:animation?] = true
        @flags[:state?] = true
      when :mob
        @profile.appearance.to_mob(assets[:mob_id])
        @flags[:state?] = true
      when :overhead
        @profile.appearance.head_to(assets[:head_icon] <= 7 && assets[:head_icon] >= -1 ? assets[:head_icon] : 0)
        @flags[:state?] = true
      end
    end

    # This function is called after every flush. It's primary purpose is to reset update flags while observering it's supplied `exempt` list.
    # @param exempt [Hash] a hash of exempt flags that should not be reset.
    def post_pulse(exempt = {})
      @flags[:region?] = false
      @flags[:state?] = exempt[:state?] || false
      @flags[:chat?] = exempt[:chat?] || false
      @flags[:teleport?] = exempt[:teleport?] || false
      @flags[:graphic?] = exempt[:graphic?] || false
      @flags[:animation?] = exempt[:animation?] || false
      @movement[:handler].process if @flags[:moved?]
    end

    def load_inventory
      if !@profile[:inventory].nil?
        @inventory = RuneRb::Game::Containers::Inventory.restore(self)
        log(RuneRb::COL.green("Restored Inventory for #{@profile[:name]}")) if RuneRb::DEBUG
      else
        @inventory = RuneRb::Game::Containers::Inventory.new
        log(RuneRb::COL.magenta("New Inventory set for #{@profile[:name]}")) if RuneRb::DEBUG
      end
      @session.write_inventory(28, @inventory.data)
    end

    def load_equipment
      if !profile[:equipment].nil? && !Oj.load(profile[:equipment]).empty?
        @equipment = RuneRb::Entity::Equipment.restore(self)
        log(RuneRb::COL.green("Restored Equipment for #{@profile[:name]}")) if RuneRb::DEBUG
      else
        @equipment = RuneRb::Entity::Equipment.new
        log(RuneRb::COL.magenta("New Equipment set for #{@profile[:name]}")) if RuneRb::DEBUG
      end
      @session.write_equipment(@equipment.data)
    end

    def logout
      RuneRb::Game::Containers::Inventory.dump(self)
      RuneRb::Entity::Equipment.dump(self)
    end

    def appearance
      @profile.appearance
    end

    def update_region
      @region = @position
    end

    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
    end
  end
end
