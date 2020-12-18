module RuneRb::Network::Meta
  # A single SidebarFrame
  class SwitchSidebarFrame < RuneRb::Network::MetaFrame

    # Called when a new SidebarFrame is created.
    def initialize(data)
      super(71)
      parse(data)
    end

    private

    # Parses the data passed to the initializer
    # @param data [Hash] the data to parse.
    def parse(data)
      write_short(data[:form])
      write_byte(data[:menu_id], :A)
    end
  end
end