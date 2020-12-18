module RuneRb::Network::Meta
  # Writes a pair of Central regional coordinates to a client.
  class CenterRegionFrame < RuneRb::Network::MetaFrame
    # Called when a new CenterRegionFrame is created.
    # @param regional [RuneRb::Game::Map::Regional] the regional object whose coordinates will be sent.
    def initialize(regional)
      super(73)
      parse(regional)
    end

    private

    # Parses the data and writes it to the payload.
    def parse(data)
      log "Writing [x: #{data[:x]}, y: #{data[:y]}]" if RuneRb::GLOBAL[:RRB_DEBUG]
      write_short(data[:x], :A)
      write_short(data[:y])
    end
  end
end