# Functions allowing robust reading of different data types from an internal payload.
module RuneRb::Base::Patches::LegacyReadable
  using RuneRb::Base::Patches::IntegerRefinements
  using RuneRb::Base::Patches::StringRefinements

  # Read database from the payload according to the option parameter.
  # @param type [Symbol] the type of database to read
  # @param opt [Hash] options that are to be observed when reading the database.
  def read(type = :byte, opt = { signed: false, mutation: :STD, order: :BIG })
    return unless RuneRb::Base::Types::Message.validate(self, :read, opt)

    case type
    when *RuneRb::RW_TYPES[:byte] then read_byte(opt[:signed] || false, opt[:mutation] || :STD)
    when *RuneRb::RW_TYPES[:short] then read_short(opt[:mutation] || :STD, opt[:order] || :BIG)
    when *RuneRb::RW_TYPES[:medium] then read_medium(opt[:mutation] || :STD, opt[:order] || :BIG)
    when *RuneRb::RW_TYPES[:int] then read_int(opt[:mutation] || :STD, opt[:order] || :BIG)
    when *RuneRb::RW_TYPES[:long] then read_long
    when *RuneRb::RW_TYPES[:string] then read_string
    when :bytes then read_bytes(opt[:amount], opt[:mutation])
    when :reverse_bytes, :negative_bytes, :reverse, :negatives then read_bytes_reverse(opt[:amount] || opt[:length], opt[:mutation])
    when :io, :socket then read_from(opt[:io] || opt[:source] || opt[:socket], opt[:length])
    when :header then read_header(opt[:source])
    else raise "Unrecognized read type! #{type}"
    end
  end

  # Ensure the message is considered readable
  def readable?
    true
  end

  # @abstract parses the message object.
  def parse(_ctx); end

  private

  # Read a byte value from the payload
  # @param signed [Boolean] should the value be signed.
  # @param mut [Symbol] mutation that should be applied to the byte value.
  def read_byte(signed = false, mut = :STD)
    val = 0
    val |= mutate(@payload.slice!(0).unpack1('c'), mut)
    signed ? val : val & 0xff
  end

  # Reads a short value from the payload
  # @param mut [Symbol] mutation that should be applied to the short value
  # @param order [Symbol] they byte order to read the short value
  def read_short( mut = :STD, order = :BIG)
    val = case order
          when :BIG then (read_byte << 8) + (read_byte(false, mut))
          when :LITTLE then (read_byte(false, mut)) + (read_byte << 8)
          end
    val -= 0x10000 if val > 32767
    val
  end

  # Reads a medium value from the payload
  # @param signed [Boolean] should the value be signed.
  # @param mut [Symbol] mutation that should be applied to the medium value
  # @param order [Symbol] they byte order to read the medium value
  def read_medium(signed = false, mut = :STD, order = :BIG)
    val = case order
          when :BIG then (read_byte << 16) + (read_byte << 8) + (read_byte(false, mut))
          when :MIDDLE then (read_byte << 8) + (read_byte) + (read_byte << 16)
          when :LITTLE then (read_byte(false, mut)) + (read_byte << 8) + (read_byte << 16)
          end
    val
  end

  # Reads a integer value from the payload
  # @param mut [Symbol] mutation that should be applied to the integer value
  # @param order [Symbol] they byte order to read the integer value
  def read_int(mut = :STD, order = :BIG)
    val = case order
    when :BIG then (read_byte << 24) + (read_byte << 16) + (read_byte << 8) + (read_byte(false, mut))
    when :INVERSE_MIDDLE then (read_byte << 8) + (read_byte(false, mut)) + (read_byte << 24) + (read_byte << 16)
    when :MIDDLE then (read_byte << 16) + (read_byte << 24) + (read_byte(false, mut)) + (read_byte << 8)
    when :LITTLE then (read_byte(false, mut)) + (read_byte << 8) + (read_byte << 16) + (read_byte << 24)
    end
    val
  end

  # Reads a long value from the payload
  def read_long
    chunk_1 = read_int & 0xFFFFFFFF
    chunk_2 = read_int & 0xFFFFFFFF
    (chunk_1 << 32) + chunk_2
  end

  # Reads a string from the payload
  # @return [String] the resulting string.
  def read_string
    val = ''
    while (res = read)
      break if res == 10

      val << res
    end
    val
  end

  # Read multiple bytes from the payload
  # @param amount [Integer] the amount of bytes to read
  # @param mut [Symbol] the mutation to apply to read bytes.
  def read_bytes(amount, mut)
    amount.times.each_with_object([]) { |_idx, arr| arr << read_byte(false, mut) }
  end

  # Probably did this wrong
  def read_bytes_reverse(amount, mut)
    amount.times.inject([]) { |arr| arr << mutate(@payload.reverse.next_byte, mut); arr }
  end

  def read_from(io, length)
    raise "Closed IO" if io.closed?

    io.read_nonblock(length, @payload)
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