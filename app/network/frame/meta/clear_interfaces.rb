module RuneRb::Network::Meta
  # Clears all interfaces from the client's view
  class ClearInterfacesFrame < RuneRb::Network::MetaFrame
    # Called when a ClearInterfaceFrame object is created
    def initialize
      super(29)
    end
  end
end