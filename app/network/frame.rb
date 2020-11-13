module RuneRb::Network
  # A basic network frame
  class Frame
    attr :header, :payload

    Header = Struct.new(:op_code, :length) do
      def inspect
        RuneRb::COL.cyan("[OpCode]: #{self.op_code} || [Size]: #{self.length} || ")
      end
    end

    def initialize(op_code = -1)
      @header = Header.new(op_code)
    end

    def inspect
      @header.inspect + RuneRb::COL.blue("[Payload]: #{@payload&.unpack('c*')}")
    end
  end

  # An incoming frame
  class InFrame < Frame
    using RuneRb::Patches::StringOverrides
    using RuneRb::Patches::IntegerOverrides

    def initialize(op_code)
      super(op_code & 0xFF)
      @payload = ''
    end

    def push(data)
      @payload << data
    end

    # Reads the next 24-bit integer
    def read_int24
      val = 0
      val |= read_byte << 16
      val |= read_byte << 8
      val |= read_byte
      val
    end

    # Read a byte from the underlying buffer
    # @param signed [Boolean] Should the byte be signed?
    # @param type [Symbol] the type of byte to read. Accommodates Jagex-specific types (:STD, :A, :C, :S)
    def read_byte(signed = false, type = :STD)
      valid_type?(type)
      val = @payload.next_byte
      case type
      when :A then val -= 128
      when :C then val = -val
      when :S then val = 128 - val
      end
      signed ? val : val & 0xff
    end

    # Read multiple bytes from the buffer
    # @param amount [Integer] the amount of bytes to read
    # @param type [Symbol] the type of bytes to read. Accommodates Jamflex-specific types (:STD, :A, :C, :S)
    def read_bytes(amount, type)
      amount.times.each_with_object([]) { |_idx, arr| arr << read_byte(true, type) }
    end

    # Probably did this wrong
    def read_bytes_reverse(amount, type)
      itrs = amount
      amount.times.each_with_object([]) do |_itr, arr|
        arr << @payload.byte_from(itrs -= 1)
      end
    end

    def read_short(signed = false, type = :STD, order = :BIG)
      valid_order?(order)
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

    def read_int(signed = true, type = :STD, order = :BIG)
      valid_order?(order)
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

    def read_long(type = :STD, order = :BIG)
      valid_order?(order)
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

    def read_string
      val = ''
      while (res = read_byte(false))
        break if res == 10

        val << res
      end
      val
    end

    private

    def valid_access?(type)
      raise 'Invalid access type for write!' unless type == @access
    end

    def valid_order?(order)
      raise 'Unrecognized byte order!' unless RuneRb::Network::BYTE_ORDERS.include?(order)
    end

    def valid_type?(type)
      raise 'Unrecognized type!' unless RuneRb::Network::BYTE_TYPES.include?(type)
    end
  end

  class MetaFrame < Frame
    using RuneRb::Patches::StringOverrides
    using RuneRb::Patches::IntegerOverrides

    Type = Struct.new(:fixed, :variable_short)

    # Called when a new MetaFrame is created
    def initialize(op_code, fixed = true, variable_short = false)
      super(op_code)
      @payload = ''
      @access = :BYTE
      @type = Type.new(fixed, variable_short)
      @bit_position = 0
    end

    # Compiles the MetaFrame object to a binary string ready to be sent.
    def compile
      @payload.prepend(compile_header)
    end

    # Switches the access mode for this buffer. If the current access mode is :BYTE it will be :BIT and vice versa.
    def switch_access
      @access = @access == :BYTE ? :BIT : :BYTE
      self
    end

    # Write a byte to the underlying buffer.
    # @param value [Integer, String, StringIO] the byte to write to the underlying buffer.
    # @param type [Symbol] the type of byte to write. Used to accommodate Jagex-specific byte modifiers (:STD, :A, :C, :S)
    def write_byte(value, type = :STD)
      valid_access?(:BYTE)
      valid_type?(type)
      @payload << [parse_type(value, type)].pack('c')
      self
    end

    # Writes multiple bytes to the underlying buffer.
    def write_bytes(data)
      if data.class == RuneRb::Network::MetaFrame
        @payload << data.compile
      else
        data.each { |byte| write_byte(byte) }
      end
      self
    end

    def parse_type(value, type)
      case type
      when :A, :a then value += 128
      when :C, :c then value = -value
      when :S, :s then value = 128 - value
      end
      value
    end

    # Write a short to the underlying buffer.
    # @param value [Integer, String, StringIO] the byte to write to the underlying buffer.
    # @param type [Symbol] the type of byte to write. Used to accommodate Jagex-specific byte modifiers (:STD, :A, :C, :S)
    # @param order [Symbol] the bit order in which to write the short. Endianness. (:BIG, :LITTLE)
    def write_short(value, type = :STD, order = :BIG)
      case order
      when :BIG
        write_byte((value >> 8))
        write_byte(value, type)
      when :LITTLE
        write_byte(value, type)
        write_byte((value >> 8))
      end
      self
    end

    # Write an integer value to the underlying buffer.
    # @param value [Integer, String, StringIO] the byte to write to the underlying buffer.
    # @param type [Symbol] the type of byte to write. Used to accommodate Jagex-specific byte modifiers (:STD, :A, :C, :S)
    # @param order [Symbol] the bit order in which to write the short. Endianness. (:BIG, :MIDDLE, :INVERSE_MIDDLE, :LITTLE)
    def write_int(value, type = :STD, order = :BIG)
      case order
      when :BIG
        write_byte((value >> 24).signed(:byte))
        write_byte((value >> 16).signed(:byte))
        write_byte((value >> 8).signed(:byte))
        write_byte(value.signed(:byte), type)
      when :MIDDLE
        write_byte((value >> 8).signed(:byte))
        write_byte(value.signed(:byte), type)
        write_byte((value >> 24).signed(:byte))
        write_byte((value >> 16).signed(:byte))
      when :INVERSE_MIDDLE
        write_byte((value >> 16).signed(:byte))
        write_byte((value >> 24).signed(:byte))
        write_byte(value.signed(:byte), type)
        write_byte((value >> 8).signed(:byte))
      when :LITTLE
        write_byte(value.signed(:byte), type)
        write_byte((value >> 8).signed(:byte))
        write_byte((value >> 16).signed(:byte))
        write_byte((value >> 24).signed(:byte))
      end
      self
    end

    # Write a 'tri-byte' to the underlying buffer.
    # @param value [Integer] the value to write.
    # @param order [Symbol] the bit order in which to write the value.
    def write_tribyte(value, order = :BIG)
      case order
      when :BIG
        write_byte((value >> 16).signed(:byte))
        write_byte((value >> 8).signed(:byte))
        write_byte(value.signed(:byte))
      when :MIDDLE
        write_byte((value >> 8).signed(:byte))
        write_byte(value.signed(:byte))
        write_byte((value >> 16).signed(:byte))
      when :LITTLE
        write_byte(value.signed(:byte))
        write_byte((value >> 8).signed(:byte))
        write_byte((value >> 16).signed(:byte))
      end
    end

    # Write a long value to the underlying buffer.
    # @param value [Integer, String, StringIO] the byte to write to the underlying buffer.
    # @param type [Symbol] the type of byte to write. Used to accommodate Jagex-specific byte modifiers (:STD, :A, :C, :S)
    # @param order [Symbol] the bit order in which to write the short. Endianness. (:BIG, :LITTLE)
    def write_long(value, type = :STD, order = :BIG)
      case order
      when :BIG
        write_byte((value >> 56))
        write_byte((value >> 48))
        write_byte((value >> 40))
        write_byte((value >> 32))
        write_byte((value >> 24))
        write_byte((value >> 16))
        write_byte((value >> 8))
        write_byte(value.signed(:int), type)
      when :LITTLE
        write_byte(value.signed(:int), type)
        write_byte((value >> 8))
        write_byte((value >> 16))
        write_byte((value >> 24))
        write_byte((value >> 32))
        write_byte((value >> 40))
        write_byte((value >> 48))
        write_byte((value >> 56))
      end
      self
    end

    # Write a string value to the underlying buffer. This will be escaped/terminated with a 10/\n value.
    # @param string [String, StringIO] the byte to write to the underlying buffer.
    def write_string(string)
      @payload << string.force_encoding(Encoding::BINARY)
      write_byte(10)
      self
    end

    # Write a collection of bytes in reverse. *Not sure if I did this right.
    # @param values [Array] collection of values to write to the underlying buffer.
    def write_reverse_bytes(values)
      values.reverse.each { |v| write_byte(v) }
      self
    end

    # Write multiple bits to the underlying buffer.
    # @param amount [Integer] the amount of bits to occupy with the following value.
    # @param value [Integer] the value to occupy the former amount of bits.
    def write_bits(amount, value)
      valid_access? :BIT
      byte_pos = @bit_position >> 3
      bit_offset = 8 - (@bit_position & 7)
      @bit_position += amount

      while amount > bit_offset
        @payload[byte_pos] = [0].pack('c') if @payload[byte_pos].nil?
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') | (value >> (amount - bit_offset)) & RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
        byte_pos += 1
        amount -= bit_offset
        bit_offset = 8
      end

      @payload[byte_pos] = [0].pack('c') if @payload[byte_pos].nil?

      if amount == bit_offset
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') | (value & RuneRb::Network::BIT_MASK_OUT[bit_offset]))].pack('c')
      else
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') & ~(RuneRb::Network::BIT_MASK_OUT[amount] << (bit_offset - amount)))].pack('c')
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') | ((value & RuneRb::Network::BIT_MASK_OUT[amount]) << (bit_offset - amount)))].pack('c')
      end

      self
    end

    # Pad the underlying buffer until the next byte.
    def write_padding
      valid_access? :BIT
      write_bit(false) until (@payload.size % 2).zero?
    end

    # Write a single bit with a value of 1 or 0 depending on the parameter.
    # @param flag [Boolean] the flag determining the value.
    def write_bit(flag)
      valid_access? :BIT
      write_bits(1, flag ? 1 : 0)
      self
    end

    # The size of the frame's payload
    # @return [Integer] the size of the frame's payload
    def size
      @payload.size
    end

    private

    def compile_header
      head = ''
      return head if @header[:op_code] == -1

      head << [@header[:op_code]].pack('C')
      return head if @type[:fixed]

      head << [payload.size].pack(@type[:variable_short] ? 'n' : 'C')
      head
    end

    def valid_access?(type)
      raise 'Invalid access type for write!' unless type == @access
    end

    def valid_order?(order)
      raise 'Unrecognized byte order!' unless RuneRb::Network::BYTE_ORDERS.include?(order)
    end

    def valid_type?(type)
      raise 'Unrecognized type!' unless RuneRb::Network::BYTE_TYPES.include?(type)
    end
  end
end
