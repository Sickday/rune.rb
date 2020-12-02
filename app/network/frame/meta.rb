module RuneRb::Net
  # A Frame created by the application.
  class MetaFrame < Frame
    include RuneRb::Internal::Log

    using RuneRb::Patches::StringOverrides
    using RuneRb::Patches::IntegerOverrides

    # Called when a new MetaFrame is created
    def initialize(op_code, fixed = true, variable_short = false)
      super(op_code)
      @payload = ''
      @access = :BYTE
      @type = { fixed: fixed, variable_short: variable_short }
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
      return unless valid_access?(:BYTE)

      return unless valid_type?(type)

      @payload << [parse_type(value, type)].pack('c')
      self
    end

    # Writes multiple bytes to the underlying buffer.
    def write_bytes(data)
      if data.is_a?(RuneRb::Net::MetaFrame)
        @payload << data.peek
      elsif data.instance_of?(String)
        @payload << data
      elsif data.instance_of?(Array)
        data.each { |byte| write_byte(byte) }
      end
      self
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
        write_byte((value >> 24))
        write_byte((value >> 16))
        write_byte((value >> 8))
        write_byte(value, type)
      when :MIDDLE
        write_byte((value >> 8))
        write_byte(value, type)
        write_byte((value >> 24))
        write_byte((value >> 16))
      when :INVERSE_MIDDLE
        write_byte((value >> 16))
        write_byte((value >> 24))
        write_byte(value, type)
        write_byte((value >> 8))
      when :LITTLE
        write_byte(value, type)
        write_byte((value >> 8))
        write_byte((value >> 16))
        write_byte((value >> 24))
      end
      self
    end

    # Write a 'tri-byte' to the underlying buffer.
    # @param value [Integer] the value to write.
    # @param order [Symbol] the bit order in which to write the value.
    def write_tribyte(value, order = :BIG)
      case order
      when :BIG
        write_byte((value >> 16))
        write_byte((value >> 8))
        write_byte(value)
      when :MIDDLE
        write_byte((value >> 8))
        write_byte(value)
        write_byte((value >> 16))
      when :LITTLE
        write_byte(value)
        write_byte((value >> 8))
        write_byte((value >> 16))
      end
      self
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
        write_byte(value, type)
      when :LITTLE
        write_byte(value, type)
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

    # Writes a 'smart' to the buffer. If the value is greater than 128 a byte is written, else a short is written.
    # @param value [Integer] the value to write.
    def write_smart(value)
      value > 128 ? write_byte(value) : write_short(value)
    end

    # Write a collection of bytes in reverse. *Not sure if I did this right.
    # @param values [Array, String] collection of values to write to the underlying buffer.
    def write_reverse_bytes(values)
      return if values.empty?

      case values
      when Array
        values.reverse.each { |val| write_byte(val) }
      when String
        values.bytes.reverse.each { |val| write_byte(val) }
      else
        @payload << values
      end
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
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') & ~RuneRb::Net::BIT_MASK_OUT[bit_offset])].pack('c')
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') | (value >> (amount - bit_offset)) & RuneRb::Net::BIT_MASK_OUT[bit_offset])].pack('c')
        byte_pos += 1
        amount -= bit_offset
        bit_offset = 8
      end

      @payload[byte_pos] = [0].pack('c') if @payload[byte_pos].nil?

      if amount == bit_offset
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') & ~RuneRb::Net::BIT_MASK_OUT[bit_offset])].pack('c')
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') | (value & RuneRb::Net::BIT_MASK_OUT[bit_offset]))].pack('c')
      else
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') & ~(RuneRb::Net::BIT_MASK_OUT[amount] << (bit_offset - amount)))].pack('c')
        @payload[byte_pos] = [(@payload[byte_pos].unpack1('c') | ((value & RuneRb::Net::BIT_MASK_OUT[amount]) << (bit_offset - amount)))].pack('c')
      end

      self
    end

    # Pad the underlying buffer until the next byte.
    def write_padding
      valid_access? :BIT
      write_bit(false) until (@payload.size % 2).zero?
      self
    end

    # Write a single bit with a value of 1 or 0 depending on the flag parameter.
    # @param flag [Boolean] the flag determining the value.
    def write_bit(flag)
      valid_access? :BIT
      write_bits(1, flag ? 1 : 0)
      self
    end

    # The size of the frame's payload
    # @return [Integer] the size of the frame's payload
    def size
      @payload.bytesize
    end

    # Returns a copy of the payload for peeking.
    # @return [String, StringIO] a copy of the payload
    def peek
      @payload.dup
    end

    private

    def compile_header
      return if @header[:op_code] == -1

      head = ''
      head << [@header[:op_code]].pack('C')
      return head if @type[:fixed]

      head << [@payload.bytesize].pack(@type[:variable_short] ? 'n' : 'C')
      head
    end

    def valid_access?(type)
      raise 'Invalid access type for write!' unless type == @access

      true
    end
  end
end