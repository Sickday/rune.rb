module RuneRb::IO::Helpers::Writeable

  # Write data to the payload.
  # @param type [Symbol] the type of value to write.
  # @param value [Integer, String, Message, Array] the value to write.
  def write(value, type: :byte, mutation: :STD, order: 'BIG', options: {})
    return unless RuneRb::IO::Helpers::Validation.validate(self, 'write', { mutation: mutation, order: order })

    case type
    when :bits then write_bits(value, options[:amount] || 1)
    when :bit then write_bit(value)
    when :byte then write_byte(value, mutation: mutation)
    when :bytes then write_bytes(value)
    when :short then write_short(value, mutation: mutation, order: order)
    when :medium then write_medium(value, mutation: mutation, order: order)
    when :int then write_int(value, mutation: mutation, order: order)
    when :long then write_long(value, mutation: mutation, order: order)
    when :smart then write_smart(value, mutation: mutation, signed: options[:signed] || false)
    when :string then write_string(value)
    when :reverse_bytes then write_reverse_bytes(value)
    else raise "Unrecognized write type! #{type}"
    end

    self
  end

  # Enables or Disables bit writing by setting the {Buffer#bit_access} variable.
  def switch_access
    @bit_access = !@bit_access
  end

  def finish_access
    @bit_position = (@bit_position + 7) / 8
    switch_access
  end

  private

  # Write a byte value to the payload.
  # @param value [Integer] the byte value to write.
  # @param mutation [String] mutations made to the byte.
  def write_byte(value, mutation: :STD)
    @data.concat([mutate(value, mutation)].pack('C'))
  end

  # Write a short value to the payload.
  # @param value [Integer] the short value to write.
  # @param mutation [String] the type of byte to write.
  # @param order [String] the order in which bytes will be written.
  def write_short(value, mutation: :STD, order: 'BIG')
    case order
    when 'BIG'
      write_byte(value >> 8)
      write_byte(value, mutation: mutation)
    when 'LITTLE'
      write_byte(value, mutation: mutation)
      write_byte(value >> 8)
    else raise "Unrecognized bit order: #{order}"
    end
  end

  # Write a medium value to the payload.
  # @param value [Integer] the medium value to write.
  # @param mutation [String] the mutation made to the byte.
  # @param order [String] the order in which bytes will be written.
  def write_medium(value, mutation: :STD, order: 'BIG')
    case order
    when 'BIG'
      write_byte(value >> 16)
      write_byte(value >> 8)
      write_byte(value, mutation: mutation)
    when 'MIDDLE'
      write_byte(value >> 8)
      write_byte(value, mutation: mutation)
      write_byte(value >> 16)
    when 'LITTLE'
      write_byte(value, mutation: mutation)
      write_byte(value >> 8)
      write_byte(value >> 16)
    else raise "Unrecognized bit order: #{order}"
    end
  end

  # Write a integer value to the payload.
  # @param value [Integer] the integer value to write.
  # @param mutation [String] the type of byte to write.
  # @param order [String] the order in which bytes will be written.
  def write_int(value, mutation: :STD, order: 'BIG')
    case order
    when 'BIG'
      write_byte(value >> 24)
      write_byte(value >> 16)
      write_byte(value >> 8)
      write_byte(value, mutation: mutation)
    when 'MIDDLE'
      write_byte(value >> 8)
      write_byte(value, mutation: mutation)
      write_byte(value >> 24)
      write_byte(value >> 16)
    when 'INVERSE_MIDDLE'
      write_byte(value >> 16)
      write_byte(value >> 24)
      write_byte(value, mutation: mutation)
      write_byte(value >> 8)
    when 'LITTLE'
      write_byte(value, mutation: mutation)
      write_byte(value >> 8)
      write_byte(value >> 16)
      write_byte(value >> 24)
    else raise "Unrecognized bit order: #{order}"
    end
  end

  # Write a long value to the payload.
  # @param value [Integer] the long value to write.
  # @param mutation [String] the type of byte to write.
  # @param order [String] the order in which bytes will be written.
  def write_long(value, mutation: :STD, order: 'BIG')
    case order
    when 'BIG'
      (RuneRb::Network::BYTE_SIZE * 7).downto(0) { |div| ((div % 8).zero? and div.positive?) ? write_byte(value >> div) : next }
      write_byte(value, mutation: mutation)
    when 'LITTLE'
      write_byte(value, mutation: mutation)
      (0).upto(RuneRb::Network::BYTE_SIZE * 7) { |div| ((div % 8).zero? and div.positive?) ? write_byte(value >> div) : next }
    else raise "Unrecognized bit order: #{order}"
    end
  end

  # Write a string value to the payload. This will be escaped/terminated with a \n[10] value.
  # @param string [String, StringIO] the byte to write to the payload.
  def write_string(string)
    @data.concat(string.force_encoding(Encoding::BINARY))
    write_byte(10)
  end

  # Write a 'smart' value to the payload.
  #
  # @param value [Integer] the smart value to write.
  # @param mutation [String] an optional mutation to apply to the written smart value.
  def write_smart(value, mutation: :STD, signed: false)
    case signed
    when true
      value > 128 ? write_byte(value, mutation: mutation) + 64 : write_short(value, mutation: mutation) + 49_152
    when false
      value > 128 ? write_byte(value, mutation: mutation) : write_short(value, mutation: mutation) + 32_768
    end
  end

  # Writes multiple bytes to the payload.
  # @param values [String, Array, RuneRb::Network::Buffer] the values whose bytes will be written.
  def write_bytes(values)
    case values
    when Array then values.each { |byte| write_byte(byte.to_i) }
    when RuneRb::Network::Message then @data.concat(values.body.data)
    when RuneRb::Network::Buffer then @data.concat(values.data)
    when String then @data.concat(values)
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
    write_bits(flag == true ? 1 : 0, 1)
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
      @data[byte_pos] = [0].pack('c') if @data[byte_pos].nil?
      @data[byte_pos] = [(@data[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
      @data[byte_pos] = [(@data[byte_pos].unpack1('c') | (value >> (amount - bit_offset)) & RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
      byte_pos += 1
      amount -= bit_offset
      bit_offset = 8
    end

    @data[byte_pos] = [0].pack('c') if @data[byte_pos].nil?

    if amount == bit_offset
      @data[byte_pos] = [(@data[byte_pos].unpack1('c') & ~RuneRb::Network::BIT_MASK_OUT[bit_offset])].pack('c')
      @data[byte_pos] = [(@data[byte_pos].unpack1('c') | (value & RuneRb::Network::BIT_MASK_OUT[bit_offset]))].pack('c')
    else
      @data[byte_pos] = [(@data[byte_pos].unpack1('c') & ~(RuneRb::Network::BIT_MASK_OUT[amount] << (bit_offset - amount)))].pack('c')
      @data[byte_pos] = [(@data[byte_pos].unpack1('c') | ((value & RuneRb::Network::BIT_MASK_OUT[amount]) << (bit_offset - amount)))].pack('c')
    end
  end
end

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
