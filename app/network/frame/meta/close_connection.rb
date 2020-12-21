module RuneRb::Network::Meta
  # Writes a close connection frame to a client.
  class CloseConnectionFrame < RuneRb::Network::MetaFrame
    # Called when a new CloseConnectionFrame is created.
    def initialize
      super(5)
    end
  end
end