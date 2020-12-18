module RuneRb::Network
  # A basic network frame
  class Frame
    using RuneRb::System::Patches::StringOverrides
    using RuneRb::System::Patches::IntegerOverrides

    # @return [Hash] the header for the frame
    attr :header

    # @return [String, StringIO] the payload of the Frame.
    attr :payload

    # Called when a new Frame is created
    # @param op_code [Integer] the  operation code that will be used in the Frame's header.
    def initialize(op_code = -1, length = -1)
      @header = { op_code: op_code & 0xFF, length: length & 0xFF }
    end

    # Reads data from a socket into the frame's buffer
    # @param socket [TCPSocket] the socket to read from
    # @param size [Integer] the amount of bytes to read from the socket.
    def read(socket, size = @header[:length])
      @payload = NIO::ByteBuffer.new(size)
      @payload.read_from(socket) unless size.zero?
      @payload.flip
    end

    # Parses the value based on the type passed.
    # @param value [Integer, String, StringIO] the value to parse
    # @param type [Symbol] the type to parse
    def parse_type(value, type)
      case type
      when :A, :a then value += 128
      when :C, :c then value = -value
      when :S, :s then value = 128 - value
      end
      value
    end

    # Read a byte from the underlying buffer
    # @param signed [Boolean] Should the byte be signed?
    # @param type [Symbol] the type of byte to read. Accommodates Jagex-specific types (:STD, :A, :C, :S)
    def read_byte(signed = false, type = :STD)
      return unless valid_type?(type)

      if signed
        parse_type(@payload.get(1).unpack1('c'), type)
      else
        parse_type(@payload.get(1).unpack1('C'), type)
      end
    end

    # Read multiple bytes from the buffer
    # @param amount [Integer] the amount of bytes to read
    # @param type [Symbol] the type of bytes to read. Accommodates Jamflex-specific types (:STD, :A, :C, :S)
    def read_bytes(amount, type)
      amount.times.each_with_object([]) { |_idx, arr| arr << read_byte(true, type) }
    end

    # Probably did this wrong
    def read_bytes_reverse(amount, type)
      amount.times.inject([]) do |arr|
        @payload.flip
        arr << read_byte
        arr
      end
    end

    # Read a short value from the buffer
    # @param signed [Boolean] should the value be signed
    # @param type [Symbol] the type of value to read.
    # @param order [Symbol] the byte order of the short to read.
    def read_short(signed = false, type = :STD, order = :BIG)
      return unless valid_order?(order)

      val = 0
      case order
      when :BIG
        val |= read_byte(signed) << 8
        val |= read_byte(signed, type)
      when :LITTLE
        val |= read_byte(signed, type)
        val |= read_byte(signed) << 8
      end
      signed ? val : val & 0xffff
    end

    # Reads an integer from the payload
    # @param signed [Boolean] should the integer be signed?
    # @param type [Symbol] the type of value to read
    # @param order [Symbol] the byte order to read in.
    def read_int(signed = true, type = :STD, order = :BIG)
      return unless valid_order?(order)

      val = 0
      case order
      when :BIG
        val |= read_byte(false, type) << 24
        val |= read_byte(false, type) << 16
        val |= read_byte(false, type) << 8
        val |= read_byte(false, type)
      when :MIDDLE
        val |= read_byte(false, type) << 8
        val |= read_byte(false, type)
        val |= read_byte(false, type) << 24
        val |= read_byte(false, type) << 16
      when :INVERSE_MIDDLE
        val |= read_byte(false, type) << 16
        val |= read_byte(false, type) << 24
        val |= read_byte(false, type)
        val |= read_byte(false, type) << 8
      when :LITTLE
        val |= read_byte(false, type)
        val |= read_byte(false, type) << 8
        val |= read_byte(false, type) << 16
        val |= read_byte(false, type) << 24
      end
      signed ? val : val & 0xfff
    end

    # Reads the next 24-bit integer
    # @param signed [Boolean] should the 24-bit integer be signed?
    def read_int24(signed = true)
      val = 0
      val |= read_byte << 16
      val |= read_byte << 8
      val |= read_byte
      signed ? val : val & 0xff
    end

    # Reads a long value from the payload
    # @param type [Symbol] the type of long value to read
    # @param order [Symbol] they byte order to read the long in.
    def read_long(type = :STD, order = :BIG)
      return unless valid_order?(order)

      val = 0
      case order
      when :BIG
        val |= read_byte(false) << 56
        val |= read_byte(false) << 48
        val |= read_byte(false) << 40
        val |= read_byte(false) << 32
        val |= read_byte(false) << 24
        val |= read_byte(false) << 16
        val |= read_byte(false) << 8
        val |= read_byte(false, type)
      when :LITTLE
        val |= read_byte(false, type)
        val |= read_byte(false) << 8
        val |= read_byte(false) << 16
        val |= read_byte(false) << 24
        val |= read_byte(false) << 32
        val |= read_byte(false) << 40
        val |= read_byte(false) << 48
        val |= read_byte(false) << 56
      end
      val
    end

    # Reads a 'tri-byte' from the underlying buffer.
    # @param type [Symbol] the type of Tri byte to read
    # @param order [Symbol] the bit order in which to read the value.
    def read_tribyte(type = :STD, order = :BIG)
      return unless valid_order?(order)

      val = 0
      case order
      when :BIG
        val |= read_byte(false) << 16
        val |= read_byte(false) << 8
        val |= read_byte(false, type)
      when :MIDDLE
        val |= read_byte(false) << 8
        val |= read_byte(false)
        val |= read_byte(false) << 16
      when :LITTLE
        val |= read_byte(false)
        val |= read_byte(false) << 8
        val |= read_byte(false) << 16
      end
      val
    end

    # Reads a string from the payload
    # @return [String] the resulting string.
    def read_string
      val = ''
      while (res = read_byte(false))
        break if res == 10

        val << res
      end
      val
    end

    def inspect
      case @payload
      when NIO::ByteBuffer
        RuneRb::COL.cyan("[OpCode]: #{@header[:op_code]} || [Size]: #{@payload.limit}")
      when String
        RuneRb::COL.cyan("[OpCode]: #{@header[:op_code]} || [Size]: #{@payload&.length} || #{RuneRb::COL.blue("[Payload]: #{@payload&.unpack('c*')}")}")
      end
    end

    private

    def valid_order?(order)
      raise 'Unrecognized byte order!' unless RuneRb::Network::BYTE_ORDERS.include?(order)

      true
    end

    def valid_type?(type)
      true
    end
  end
end
