module RuneRb::Net::Meta
  # Writes a close connection frame to a client.
  class CloseConnectionFrame < RuneRb::Net::MetaFrame
    # Called when a new CloseConnectionFrame is created.
    def initialize
      super(109)
    end
  end
end