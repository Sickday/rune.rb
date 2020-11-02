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
    end

    # Compiles the MetaFrame object to a binary string ready to be sent.
    def compile
      compile_header + @payload
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
      case type
      when :A, :a then value += 128
      when :C, :c then value = -value
      when :S, :s then value = 128 - value
      end
      @payload << [value].pack('c')
      self
    end

    # Writes multiple bytes to the underlying buffer.
    def write_bytes(bytes)
      bytes.each { |byte| write_byte(byte) }
      self
    end

    # Write a short to the underlying buffer.
    # @param value [Integer, String, StringIO] the byte to write to the underlying buffer.
    # @param type [Symbol] the type of byte to write. Used to accommodate Jagex-specific byte modifiers (:STD, :A, :C, :S)
    # @param order [Symbol] the bit order in which to write the short. Endianness. (:BIG, :LITTLE)
    def write_short(value, type = :STD, order = :BIG)
      case order
      when :BIG
        write_byte((value.signed(:byte) >> 8))
        write_byte(value.signed(:byte), type)
      when :LITTLE
        write_byte(value.signed(:byte), type)
        write_byte((value.signed(:byte) >> 8))
      end
      self
    end

    # Write an integer value to the underlying buffer.
    # @param value [Integer, String, StringIO] the byte to write to the underlying buffer.
    # @param type [Symbol] the type of byte to write. Used to accommodate Jagex-specific byte modifiers (:STD, :A, :C, :S)
    # @param order [Symbol] the bit order in which to write the short. Endianness. (:BIG, :MIDDLE, :INVERSE_MIDDLE, :LITTLE)
    def write_int(value, type, order = :BIG)
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
    def write_long(value, type, order = :BIG)
      case order
      when :BIG
        write_byte((value >> 56).signed(:int))
        write_byte((value >> 48).signed(:int))
        write_byte((value >> 40).signed(:int))
        write_byte((value >> 32).signed(:int))
        write_byte((value >> 24).signed(:int))
        write_byte((value >> 16).signed(:int))
        write_byte((value >> 8).signed(:int))
        write_byte(value.signed(:int), type)
      when :LITTLE
        write_byte(value.signed(:int), type)
        write_byte((value >> 8).signed(:int))
        write_byte((value >> 16).signed(:int))
        write_byte((value >> 24).signed(:int))
        write_byte((value >> 32).signed(:int))
        write_byte((value >> 40).signed(:int))
        write_byte((value >> 48).signed(:int))
        write_byte((value >> 56).signed(:int))
      end
      self
    end

    # Write a string value to the underlying buffer. This will be escaped with a 10 value.
    # @param string [String, StringIO] the byte to write to the underlying buffer.
    def write_string(string)
      write_bytes(string.bytes)
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
        @io[byte_pos] = [0].pack('c') if @io[byte_pos].nil?
        @io[byte_pos] = [(@io[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
        @io[byte_pos] = [(@io[byte_pos].unpack1('c') | (value >> (amount - bit_offset)) & RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
        byte_pos += 1
        amount -= bit_offset
        bit_offset = 8
      end

      @io[byte_pos] = [0].pack('c') if @io[byte_pos].nil?

      if amount == bit_offset
        @io[byte_pos] = [(@io[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
        @io[byte_pos] = [(@io[byte_pos].unpack1('c') | (value & RuneRb::Network::BIT_MASK_OUT[bit_offset]))].pack('c')
      else
        @io[byte_pos] = [(@io[byte_pos].unpack1('c') & ~(RuneRb::Network::BIT_MASK_OUT[amount] << (bit_offset - amount)))].pack('c')
        @io[byte_pos] = [(@io[byte_pos].unpack1('c') | ((value & RuneRb::Network::BIT_MASK_OUT[amount]) << (bit_offset - amount)))].pack('c')
      end

      self
    end

    # Write a single bit with a value of 1 or 0 depending on the parameter.
    # @param flag [Boolean] the flag determining the value.
    def write_bit(flag)
      valid_access? :BIT
      write_bits(1, flag ? 1 : 0)
      self
    end

    private

    def compile_header
      head = ''
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
