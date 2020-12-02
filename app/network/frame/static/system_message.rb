module RuneRb::Net::Static
  class SystemMessageFrame < RuneRb::Net::MetaFrame
    # Called when a new SystemMessageFrame is created
    # @param data [Hash] the data for the frame.
    def initialize(data)
      super(253, false, false)
      parse(data)
    end

    private

    # Parses the data and writes it to the frame.
    # @param data [Hash] the data to write to the frame.
    def parse(data)
      write_string(data[:message])
    end
  end
end