module RuneRb::Entity
  class Type
    attr :flags, :status, :properties, :position

    # Called when a new Entity is created.
    def initialize(params = {})
      @properties = {}
      @status = {}
      reset_status
      reset_properties
    end

    # Reset the status attributes to their default values.
    def reset_status
      @status[:facing] = :EAST
      @status[:busy] = false
      @status[:cool_downs] = OpenStruct.new
      @status[:dead?] = false
    end

    # Reset the properties to their default values.
    def reset_properties
      @properties[:animations] = { current: 0x368, walk: 0x333, stand: 0x368 }
      @properties[:graphics] = nil
    end
  end
end