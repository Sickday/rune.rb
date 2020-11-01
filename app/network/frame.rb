module RuneRb::Network
  # A basic network frame
  class Frame
    attr :header, :payload

    Header = Struct.new(:op_code, :length) do
      def inspect
        [self.op_code, self.length].to_s
      end
    end

    def initialize(op_code = -1)
      @header = Header.new(op_code)
    end

    def inspect
      "#{@header.inspect}\#[#{@payload.unpack('c*')}]"
    end
  end

  # An incoming frame
  class InFrame < Frame
    using RuneRb::Patches::StringOverrides
    using RuneRb::Patches::IntegerOverrides

    def initialize(op_code, length)
      super(op_code)
      @header[:length] = length
    end

    def parse(socket)
      @payload = RuneRb::Network::JReadableBuffer.from(socket, @header[:length])
    end
  end
end