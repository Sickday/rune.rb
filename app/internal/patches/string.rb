# Author: Patrick <Sickday> W.
# MDate: 10/05/2020

# A module adding new functions to the String class in the form of a refinement. The functions assist when a string is used as a Stream container/buffer.
module RuneRb::Patches::StringOverrides
  refine String do

    # returns the next byte.
    def next_byte
      slice!(0).unpack1('c')
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
  end
end