module RuneRb::Net::Static
  # An OverlayInterfaceFrame sends an interface that will close on actions (like walking).
  class OverlayInterfaceFrame < RuneRb::Net::MetaFrame

    # Called when a new OverlayInterface is created.
    # @param id [Integer] the id of the interface to display
    def initialize(id)
      @id = id
      super(208)
      parse
    end

    # Writes the overlay interface id to the payload.
    def parse
      write_short(@id, :STD, :LITTLE)
    end
  end
end