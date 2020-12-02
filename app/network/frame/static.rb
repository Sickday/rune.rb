module RuneRb::Net
  # A frame that is always read and processed the same way
  class StaticFrame < Frame
    using RuneRb::Patches::StringOverrides
    using RuneRb::Patches::IntegerOverrides

    # Called when a new StaticFrame is created.
    def initialize(op_code, length)
      super(op_code)
      @header[:length] = length
    end

    # Attempts to read the frame's payload directly from a buffer object
    # @param buffer [String] the buffer to read from
    def read_payload(buffer)
      length.times { @payload << buffer.next_byte }
    end
  end
end