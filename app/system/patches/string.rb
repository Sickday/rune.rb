module RuneRb::System::Patches::StringRefinements
  refine String do
    using RuneRb::System::Patches::IntegerRefinements

    # returns the next byte.
    def next_byte
      byte = slice!(0)
      byte.nil? ? 0 : byte.unpack1('c')
    end

    # Returns the next x amount of byte values.
    # @param amount [Integer] the amount of bytes.
    def next_bytes(amount)
      amount.times.inject('') { |str| str << slice!(0) }.unpack('c*')
    end

    # returns the next byte from the provided position.
    # @param position [Integer] the offset/position to begin reading from.
    def byte_from(position)
      slice!(position).unpack1('c')
    end

    # Returns x amount of bytes from a given position.
    # @param position [Integer] the offset/position to begin reading from.
    # @param amount [Integer] the amount of bytes to read.
    def bytes_from(position, amount)
      amount.times.inject('') { |str| str << slice!(position) }.unpack('c*')
    end

    # returns the next short.
    def next_short
      slice!(0..1).unpack1('n')
    end

    # Returns the next x amount of short values.
    # @param amount [Integer] the amount of shorts.
    def next_shorts(amount)
      amount.times.inject('') { |str| str << slice!(0..1) }.unpack('n*')
    end

    # returns the next short from the provided position.
    # @param position [Integer] the offset/position to begin reading from.
    def short_from(position)
      slice!(position..(position + 1)).unpack1('n')
    end

    # Returns x amount of shorts from a given position
    # @param position [Integer] the offset/position to begin reading from.
    # @param amount [Integer] the amount of shorts to read.
    def shorts_from(position, amount)
      amount.times.inject('') { |str| str << slice!(position..(position + 1)) }.unpack('n*')
    end

    # returns the next integer.
    def next_int
      slice!(0..3).unpack1('l')
    end

    # Returns the next x amount of integer values.
    # @param amount [Integer] the amount of integers.
    def next_ints(amount)
      amount.times.inject('') { |str| str << slice!(0..3) }.unpack('l*')
    end

    # returns the next int from the provided position.
    # @param position [Integer] the offset/position to begin reading from.
    def int_from(position)
      slice!(position..(position + 3)).unpack1('l')
    end

    # Returns x amount of integers from a given position
    # @param position [Integer] the offset/position to begin reading from.
    # @param amount [Integer] the amount of integers to read.
    def ints_from(position, amount)
      amount.times.inject('') { |str| str << slice!(position..(position + 3)) }.unpack('l*')
    end

    # returns the next long.
    def next_long
      slice!(0..7).unpack1('q')
    end

    # Returns the next x amount of long values.
    # @param amount [Integer] the amount of longs.
    def next_longs(amount)
      amount.times.inject('') { |str| str << slice!(0..7) }.unpack('q*')
    end

    # returns the next long from the provided position.
    # @param position [Integer] the offset/position to begin reading from.
    def long_from(position)
      slice!(position..(position + 7)).unpack1('q')
    end

    # Returns x amount of longs from a given position.
    # @param position [Integer] the offset/position to begin reading from.
    # @param amount [Integer] the amount of longs to read.
    def longs_from(position, amount)
      amount.times.inject('') { |str| str << slice!(position..(position + 7)) }.unpack('q*')
    end

    # Returns the next terminated string.
    def next_tstring
      val = ''
      while (res = next_byte)
        break if res == 10

        val << res
      end
      val
    end

    # Returns a base37 numeric representation of the String.
    # @return [Integer] a base37 number representing the String
    def to_base37
      l = 0
      (0...length).each do |i|
        c = self[i].chr
        l *= 37
        l += (1  + self[i].bytes.first) - 65 if c >= 'A' and c <= 'Z'
        l += (1  + self[i].bytes.first) - 97 if c >= 'a' and c <= 'z'
        l += (27 + self[i].bytes.first) - 48 if c >= '0' and c <= '9'
      end
      l /= 37 while (l % 37).zero? && l != 0
      l
    end

    # Returns a string from the provided b37 numeric
    # @param base37 [Integer] the base_37 numeric to build a string from.
    def from_base37(base37)
      return self unless empty?

      chars = %w{_ a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 ! @ # $ % ^ & * ( ) - + = : ; . > < , " [ ] | ? / `}

      while base37 != 0
        original = base37.signed(:long)
        base37 = (base37 / 37).signed(:long)
        self << chars[(original - base37 * 37).signed(:int)]
      end

      reverse!
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