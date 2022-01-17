module RuneRb::Network::Helpers::Readable
  using RuneRb::Utils::Patches::IntegerRefinements

  # Read data from the payload according to the option parameter.
  # @param type [Symbol] the type of database to read
  # @param mutation [Symbol] an option mutation to apply to the read value.
  def read(type: :byte, signed: false, mutation: :STD, order: 'BIG', options: {})
    return unless RuneRb::Network::Helpers::Validation.validate(self, 'read', { bit_access: @bit_access, mutation: mutation, order: order })

    case type
    when :bits then read_bits(options[:amount])
    when :byte then read_byte(signed: signed, mutation: mutation)
    when :bytes then read_bytes(options[:amount] || 1, mutation: mutation)
    when :short then read_short(signed: signed, mutation: mutation, order: order)
    when :medium then read_medium(signed: signed, mutation: mutation, order: order)
    when :int then read_int(signed: signed, mutation: mutation, order: order)
    when :long then read_long(signed: signed, mutation: mutation, order: order)
    when :smart then read_smart(signed: signed, mutation: mutation)
    when :string then read_string
    when :reverse_bytes then read_bytes_reverse(options[:amount] || 1, mutation: mutation)
    else raise "Unrecognized read type! #{type}"
    end
  end

  private

  # Read multiple bytes from the {Buffer#data}
  # @param amount [Integer] the amount of bytes to read
  # @param mutation [Symbol] the mutation to apply to read bytes.
  def read_bytes(amount, mutation)
    amount.times.each_with_object([]) { |_idx, arr| arr << read_byte(signed: false, mutation: mutation) }
  end

  # Probably did this wrong
  # @param amount [Integer] the amount of bytes to read
  # @param mutation [Symbol] an optional mutation to apply to the result.
  def read_bytes_reverse(amount, mutation)
    @data.reverse
    value = read_bytes(amount, mutation)
    @data.reverse
    value
  end

  # Read a byte value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the byte value.
  def read_byte(mutation: :STD, signed: false)
    val = mutate(@data.slice!(0).unpack1(signed ? 'c' : 'C'), mutation)
    signed ? val.signed(:byte) : val.unsigned(:byte)
  end

  # Reads a short value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the short value
  # @param order [String] they byte order to read the short value
  def read_short(signed: false, mutation: :STD, order: 'BIG')
    val = 0
    case order
    when 'BIG'
      val += read_byte(signed: signed) << 8
      val += read_byte(mutation: mutation, signed: signed)
    when 'LITTLE'
      val += read_byte(mutation: mutation, signed: signed)
      val += read_byte(signed: signed) << 8
    else read_short(signed: signed, mutation: mutation, order: 'BIG')
    end
    val
  end

  # Reads a medium value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the medium value
  # @param order [String] they byte order to read the medium value
  def read_medium(signed: false, mutation: :STD, order: 'BIG')
    val = 0
    case order
    when 'BIG'
      val += read_byte(signed: signed) << 16
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed, mutation: mutation)
    when 'MIDDLE'
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 16
    when 'LITTLE'
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed) << 16
    else read_medium(signed: signed, mutation: mutation, order: 'BIG')
    end
    val
  end

  # Reads a integer value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the integer value
  # @param order [String] they byte order to read the integer value
  def read_int(signed: false, mutation: :STD, order: 'BIG')
    val = 0
    case order
    when 'BIG'
      val += read_byte(signed: signed) << 24
      val += read_byte(signed: signed) << 16
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed, mutation: mutation)
    when 'MIDDLE'
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 24
      val += read_byte(signed: signed) << 16
    when 'INVERSE_MIDDLE'
      val += read_byte(signed: signed) << 16
      val += read_byte(signed: signed) << 24
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 8
    when 'LITTLE'
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed) << 16
      val += read_byte(signed: signed) << 24
    else read_int(signed: signed, mutation:mutation, order: 'BIG')
    end
    val
  end

  # Reads a long value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the long value
  # @param order [String] they byte order to read the long value
  def read_long(signed: false, mutation: :STD, order: 'BIG')
    val = 0
    case order
    when 'BIG'
      (RuneRb::Network::BYTE_SIZE * 7).downto(0) { |div| ((div % 8).zero? and div.positive?) ? val |= read_byte(signed: signed) << div : next }
      val += read_byte(signed: signed, mutation: mutation)
    when 'LITTLE'
      val += read_byte(signed: signed, mutation: mutation)
      (0).upto(RuneRb::Network::BYTE_SIZE * 7) { |div| ((div % 8).zero? and div.positive?) ? val |= read_byte(signed: signed) << div: next }
    else read_long(signed: signed, mutation: mutation, order: 'BIG')
    end
    val
  end

  # Read a smart value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the long value
  def read_smart(signed: false, mutation: :STD)
    val = peek.slice(0).unpack1(signed ? 'c' : 'C')
    case signed
    when true then val < 128 ? read_byte(mutation: mutation, signed: signed) - 64 : read_short(mutation: mutation, signed: signed, order: 'BIG') - 49_152
    when false then val < 128 ? read_byte(mutation: mutation, signed: signed) : read_short(mutation: mutation, signed: signed, order: 'BIG') - 32_768
    end
  end

  # Reads a string from the {Buffer#data}
  # @return [String] the resulting string.
  def read_string
    val = ''
    while (res = read_byte; res != 10)
      break if res == "\n"

      val << res
    end
    val
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
