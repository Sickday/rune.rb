module RuneRb::Net::Static
  # Clears all interfaces from the client's view
  class ClearInterfacesFrame < RuneRb::Net::MetaFrame
    # Called when a ClearInterfaceFrame object is created
    def initialize
      super(219)
    end
  end
end