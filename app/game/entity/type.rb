module RuneRb::Entity
  class Type
    attr :flags, :status, :properties, :position

    # Called when a new Entity is created.
    def initialize
      @status = {}
      reset_status
    end

    # Reset the status attributes to their default values.
    def reset_status
      @status[:facing] = :EAST
      @status[:busy?] = false
      @status[:dead?] = false
      @cool_downs = OpenStruct.new
    end
  end
end