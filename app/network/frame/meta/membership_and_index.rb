module RuneRb::Network::Meta
  class MembersAndIndex < RuneRb::Network::MetaFrame

    # Called when a new MembersAndIndex frame is created
    # @param data [Hash] the data for the MembersAndIndex frame
    def initialize(data)
      super(126)
    end

    private

    def parse(data)
      write_byte(data[:members])
      write_short(data[:player_idx], :STD,:LITTLE)
    end
  end
end