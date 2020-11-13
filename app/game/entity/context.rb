module RuneRb::Entity
  class Context < RuneRb::Entity::Type
    include RuneRb::Types::Loggable

    attr :position, :region, :movement, :profile, :inventory

    # Called when a new Context Entity is created.
    # @param peer [RuneRb::Network::Peer] the peer to be associated with the entity.
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
                    handler: nil } #RuneRb::Game::Map::Movement.new(self) }
      load_inventory
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
    def schedule(type, assets)
      case type
      when :inventory
        @session.write_inventory(28, @inventory.data)
      when :chat
        @message[:effects] = assets[:effects]
        @message[:color] = assets[:color]
        @message[:text] = assets[:text]
        @flags[:chat?] = true
      when :teleport
        @movement[:teleport][:to] = assets[:location]
        @profile.location.set(to)
        @position = to
        @flags[:region?] = true
        @flags[:teleport?] = true
      when :graphic
        @graphic = assets[:graphic]
        @flags[:graphic?] = true
      when :animation
        @animation = assets[:animation]
        @flags[:animation?] = true
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
    end

    def load_inventory
      if !@profile[:inventory].nil?
        @inventory = RuneRb::Game::Inventory.restore(self)
        log(RuneRb::COL.green("Restored Inventory for #{@profile[:name]}")) if RuneRb::DEBUG
      else
        @inventory = RuneRb::Game::Inventory.new
        log(RuneRb::COL.magenta("New Inventory set for #{@profile[:name]}")) if RuneRb::DEBUG
      end
      @session.write_inventory(28, @inventory.data)
    end

    def logout
      RuneRb::Game::Inventory.dump(self)
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
