module Writeable
  include Constants

  # @return [String] the writeable content.
  attr :writeable

  # @return [Symbol] the access mode for the Message.
  attr :access

  # Write data to the payload.
  # @param value [Integer, String, RuneRb::Network::MetaFrame] the value to write.
  # @param opt [Hash] options for the write operation.
  def write(value, opt = { type: :byte, mutation: :STD, order: :BIG })
    return unless Message.validate(self, :write, opt)

    case opt[:type]
    when *RW_TYPES[:bit] then write_bit(value)
    when *RW_TYPES[:byte] then write_byte(value, opt[:mutation])
    when *RW_TYPES[:short] then write_short(value, opt[:mutation], opt[:order])
    when *RW_TYPES[:medium] then write_medium(value, opt[:mutation], opt[:order])
    when *RW_TYPES[:int] then write_int(value, opt[:mutation], opt[:order])
    when *RW_TYPES[:long] then write_long(value, opt[:mutation], opt[:order])
    when *RW_TYPES[:smart] then write_smart(value, opt[:mutation])
    when *RW_TYPES[:string] then write_string(value)
    when :bits then write_bits(value, opt[:amount])
    when :bytes then write_bytes(value)
    when :reverse_bytes then write_reverse_bytes(value)
    when :padding then write_padding(value)
    end

    self
  rescue StandardError => e
    puts 'An error occurred while writing!'
    puts e
    puts e.backtrace
  end

  # A function to indicate the Message is writable.
  def writeable?
    true
  end

  private

  # Write a byte value to the payload.
  # @param value [Integer] the byte value to write.
  # @param mut [Symbol] mutations made to the byte.
  def write_byte(value, mut)
    @writeable << [mutate(value, mut)].pack('c')
  end

  # Write a short value to the payload.
  # @param value [Integer] the short value to write.
  # @param mut [Symbol] the type of byte to write.
  # @param order [Symbol] the order in which bytes will be written.
  def write_short(value, mut, order)
    case order
    when :BIG
      write(value >> 8)
      write(value, mutation: mut)
    when :LITTLE
      write(value, mutation: mut)
      write(value >> 8)
    end
  end

  # Write a medium value to the payload.
  # @param value [Integer] the medium value to write.
  # @param mut [Symbol] the mutation made to the byte.
  # @param order [Symbol] the order in which bytes will be written.
  def write_medium(value, mut, order)
    case order
    when :BIG
      write(value >> 16)
      write(value >> 8)
      write(value, mutation: mut)
    when :MIDDLE
      write(value >> 8)
      write(value, mutation: mut)
      write(value >> 16)
    when :LITTLE
      write(value, mutation: mut)
      write(value >> 8)
      write(value >> 16)
    end
  end

  # Write a integer value to the payload.
  # @param value [Integer] the integer value to write.
  # @param mut [Symbol] the type of byte to write.
  # @param order [Symbol] the order in which bytes will be written.
  def write_int(value, mut, order)
    case order
    when :BIG
      write(value >> 24)
      write(value >> 16)
      write(value >> 8)
      write(value, mutation: mut)
    when :MIDDLE
      write(value >> 8)
      write(value, mutation: mut)
      write(value >> 24)
      write(value >> 16)
    when :INVERSE_MIDDLE
      write(value >> 16)
      write(value >> 24)
      write(value, mutation: mut)
      write(value >> 8)
    when :LITTLE
      write(value, mutation: mut)
      write(value >> 8)
      write(value >> 16)
      write(value >> 24)
    end
  end

  # Write a long value to the payload.
  # @param value [Integer] the long value to write.
  # @param mut [Symbol] the type of byte to write.
  # @param order [Symbol] the order in which bytes will be written.
  def write_long(value, mut, order)
    case order
    when :BIG
      (BYTE_SIZE * 7).downto(0) { |div| ((div % 8).zero? and div.positive?) ? write(value >> div) : next }
      write(value, mutation: mut)
    when :LITTLE
      write(value, mutation: mut)
      (0).upto(BYTE_SIZE * 7) { |div| ((div % 8).zero? and div.positive?) ? write(value >> div) : next }
    end
  end

  # Write a string value to the payload. This will be escaped/terminated with a 10/\n value.
  # @param string [String, StringIO] the byte to write to the payload.
  def write_string(string)
    @writeable << string.force_encoding(Encoding::BINARY)
    write(10)
  end

  # Write a 'smart' value to the payload.
  #
  # If the value is greater than 128 a byte is written, else a short is written.
  #
  # @param value [Integer] the smart value to write.
  # @param mut [Symbol] mutations to apply to the written smart value.
  def write_smart(value, mut)
    value > 128 ? write(value, mutation: mut) : write(value, type: :short, mutation: mut)
  end

  # Writes multiple bytes to the payload.
  # @param values [String, Array, RuneRb::Network::MetaFrame] the values whose bytes will be written.
  def write_bytes(values)
    case values
    when Array then values.each { |byte| write(byte) }
    when RuneRb::Network::MetaFrame then @writeable << values.peek
    when String then @writeable << values
    end
  end

  # Write a collection of bytes in reverse. *Not sure if I did this right.
  # @param values [Array, String] the values to write.
  def write_reverse_bytes(values)
    case values
    when Array then write(values.reverse, type: :bytes)
    when String then write(values.bytes.reverse, type: :bytes)
    end
  end

  # Write a single bit with a value of 1 or 0 depending on the flag parameter.
  # @param flag [Boolean] the flag
  def write_bit(flag)
    write(flag ? 1 : 0, type: :bits, amount: 1)
    self
  end

  # Write multiple bits to the payload
  # @param amount [Integer] the amount of bits to occupy.
  # @param value [Integer] the value to write.
  def write_bits(value, amount)
    byte_pos = @bit_position >> 3
    bit_offset = 8 - (@bit_position & 7)
    @bit_position += amount

    while amount > bit_offset
      @writeable[byte_pos] = [0].pack('c') if @writeable[byte_pos].nil?
      @writeable[byte_pos] = [(@writeable[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
      @writeable[byte_pos] = [(@writeable[byte_pos].unpack1('c') | (value >> (amount - bit_offset)) & RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
      byte_pos += 1
      amount -= bit_offset
      bit_offset = 8
    end

    @writeable[byte_pos] = [0].pack('c') if @writeable[byte_pos].nil?

    if amount == bit_offset
      @writeable[byte_pos] = [(@writeable[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
      @writeable[byte_pos] = [(@writeable[byte_pos].unpack1('c') | (value & RuneRb::Network::BIT_MASK_OUT[bit_offset]))].pack('c')
    else
      @writeable[byte_pos] = [(@writeable[byte_pos].unpack1('c') & ~(RuneRb::Network::BIT_MASK_OUT[amount] << (bit_offset - amount)))].pack('c')
      @writeable[byte_pos] = [(@writeable[byte_pos].unpack1('c') | ((value & RuneRb::Network::BIT_MASK_OUT[amount]) << (bit_offset - amount)))].pack('c')
    end
  end

  # Pads the underlying buffer until the next byte.
  def write_padding(with)
    write(with ? true : false, type: :bit) until (@writeable.size % 2).zero?
  end
end