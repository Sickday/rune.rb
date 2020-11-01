module RuneRb::Network
  class JReadableBuffer
    using RuneRb::Patches::StringOverrides

    def initialize(buffer = '')
      @io = buffer
    end

    # Read a byte from the underlying buffer
    # @param signed [Boolean] Should the byte be signed?
    # @param type [Symbol] the type of byte to read. Accommodates Jagex-specific types (:STD, :A, :C, :S)
    def read_byte(signed = false, type = :STD)
      valid_type?(type)
      val = @io.next_byte
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
        arr << @io.byte_from(itrs -= 1)
      end
    end

    def read_short(signed, type = :STD, order = :BIG)
      valid_order?(order)
      val = 0
      case order
      when :BIG
        val |= read_byte(false) << 8
        val |= read_byte(false, type)
      when :LITTLE
        val |= read_byte(false, type)
        val |= read_byte(false) << 8
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

    # Reset the io to an empty string
    def reset
      @io.clear
    end

    # Duplicates the underlying io and returns an unpacked 'view' of the io.
    def view
      @io.unpack('c*').to_s
    end

    def size
      @io.size
    end

    alias length size

    def write(data)
      @io << data
    end

    alias << write

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
end