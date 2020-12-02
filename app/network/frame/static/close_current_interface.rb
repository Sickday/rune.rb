module RuneRb::Net::Static
  # Closed the currently focused interface (..?)
  class CloseCurrentInterfaceFrame < RuneRb::Net::MetaFrame
    # Called when a new CloseCurrentInterfaceFrame is created.
    def initialize
      super(130)
    end
  end
end