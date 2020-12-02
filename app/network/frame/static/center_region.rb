module RuneRb::Net::Static
  # Writes a pair of Central regional coordinates to a client.
  class CenterRegionFrame < RuneRb::Net::MetaFrame
    # Called when a new CenterRegionFrame is created.
    # @param regional [RuneRb::Map::Regional] the regional object whose coordinates will be sent.
    def initialize(regional)
      super(73)
      parse(regional)
    end

    private

    # Parses the data and writes it to the payload.
    def parse(data)
      log "Writing [x: #{data[:x]}, y: #{data[:y]}]"
      write_short(data[:x], :A)
      write_short(data[:y])
    end
  end
end