# Copyright (c) 2021, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module RuneRb::System::Patches::Writeable
  include RuneRb::Network::Constants

  # @return [String] the writeable content.
  attr :writeable

  # @return [Symbol] the access mode for the Message.
  attr :access

  # Write data to the payload.
  # @param value [Integer, String, Message, Array] the value to write.
  # @param opt [Hash] options for the write operation.
  def write(value, opt = { type: :byte, mutation: :STD, order: :BIG })
    return unless RuneRb::Network::Message.validate(self, :write, opt)

    case opt[:type]
    when *RW_TYPES[:bit] then write_bit(value)
    when *RW_TYPES[:byte] then write_byte(value, opt[:mutation] || :STD)
    when *RW_TYPES[:short] then write_short(value, opt[:mutation] || :STD, opt[:order] || :BIG)
    when *RW_TYPES[:medium] then write_medium(value, opt[:mutation] || :STD, opt[:order] || :BIG)
    when *RW_TYPES[:int] then write_int(value, opt[:mutation] || :STD, opt[:order] || :BIG)
    when *RW_TYPES[:long] then write_long(value, opt[:mutation] || :STD, opt[:order] || :BIG)
    when *RW_TYPES[:smart] then write_smart(value, opt[:mutation] || :STD)
    when *RW_TYPES[:string] then write_string(value)
    when :bits then write_bits(value, opt[:amount])
    when :bytes then write_bytes(value)
    when :reverse_bytes then write_reverse_bytes(value)
    when :padding then write_padding(value)
    end
    update_length

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

  # Compiles the writeable message
  def compile
    @type == :RAW ? @payload : @payload.prepend(RuneRb::Network::Message.compile_header(@header, @type))
  end

  def switch_access
    @access = @access == :BYTE ? :BIT : :BYTE
  end

  private

  # Write a byte value to the payload.
  # @param value [Integer] the byte value to write.
  # @param mut [Symbol] mutations made to the byte.
  def write_byte(value, mut = :STD)
    @payload << [mutate(value, mut)].pack('C')
  end

  # Write a short value to the payload.
  # @param value [Integer] the short value to write.
  # @param mut [Symbol] the type of byte to write.
  # @param order [Symbol] the order in which bytes will be written.
  def write_short(value, mut = :STD, order = :BIG)
    case order
    when :BIG
      write_byte(value >> 8)
      write_byte(value, mut)
    when :LITTLE
      write_byte(value, mut)
      write_byte(value >> 8)
    end
  end

  # Write a medium value to the payload.
  # @param value [Integer] the medium value to write.
  # @param mut [Symbol] the mutation made to the byte.
  # @param order [Symbol] the order in which bytes will be written.
  def write_medium(value, mut = :STD, order = :BIG)
    case order
    when :BIG
      write_byte(value >> 16)
      write_byte(value >> 8)
      write_byte(value, mut)
    when :MIDDLE
      write_byte(value >> 8)
      write_byte(value)
      write_byte(value >> 16)
    when :LITTLE
      write_byte(value, mut)
      write_byte(value >> 8)
      write_byte(value >> 16)
    end
  end

  # Write a integer value to the payload.
  # @param value [Integer] the integer value to write.
  # @param mut [Symbol] the type of byte to write.
  # @param order [Symbol] the order in which bytes will be written.
  def write_int(value, mut = :STD, order = :BIG)
    case order
    when :BIG
      write_byte(value >> 24)
      write_byte(value >> 16)
      write_byte(value >> 8)
      write_byte(value, mut)
    when :MIDDLE
      write_byte(value >> 8)
      write_byte(value, mut)
      write_byte(value >> 24)
      write_byte(value >> 16)
    when :INVERSE_MIDDLE
      write_byte(value >> 16)
      write_byte(value >> 24)
      write_byte(value, mut)
      write_byte(value >> 8)
    when :LITTLE
      write_byte(value, mut)
      write_byte(value >> 8)
      write_byte(value >> 16)
      write_byte(value >> 24)
    end
  end

  # Write a long value to the payload.
  # @param value [Integer] the long value to write.
  # @param mut [Symbol] the type of byte to write.
  # @param order [Symbol] the order in which bytes will be written.
  def write_long(value, mut = :STD, order = :BIG)
    case order
    when :BIG
      (BYTE_SIZE * 7).downto(0) { |div| ((div % 8).zero? and div.positive?) ? write_byte(value >> div) : next }
      write_byte(value, mut)
    when :LITTLE
      write_byte(value, mut)
      (0).upto(BYTE_SIZE * 7) { |div| ((div % 8).zero? and div.positive?) ? write_byte(value >> div) : next }
    end
  end

  # Write a string value to the payload. This will be escaped/terminated with a \n[10] value.
  # @param string [String, StringIO] the byte to write to the payload.
  def write_string(string)
    @payload << string.force_encoding(Encoding::BINARY)
    write_byte(10)
  end

  # Write a 'smart' value to the payload.
  #
  # @param value [Integer] the smart value to write.
  # @param mut [Symbol] mutations to apply to the written smart value.
  def write_smart(value, mut = :STD)
    value > 128 ? write_byte(value, mut) : write_short(value, mut)
  end

  # Writes multiple bytes to the payload.
  # @param values [String, Array, RuneRb::Network::Message] the values whose bytes will be written.
  def write_bytes(values)
    case values
    when Array then values.each { |byte| write_byte(byte.to_i) }
    when RuneRb::Network::Message then @payload << values.peek
    when String then @payload << values
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
    write_bits(flag ? 1 : 0, 1)
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
  end

  # Pads the underlying buffer until the next byte.
  def write_padding(with)
    write(with ? true : false, type: :bit) until (@payload.size % 2).zero?
  end
end
