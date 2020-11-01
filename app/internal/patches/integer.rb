# Author: Patrick <Sickday> W.
# MDate: 10/05/2020
#
# A module adding overflow functions to integers to mimic the behavior of Java primitive overflow behavior.
module RuneRb::Patches::IntegerOverrides

  refine Integer do

    # Returns a binary representation in the form of an array of 1's and 0's in their respective digits.
    # @return [Array] the binary representation
    def binary_representation
      to_s(2).chars.map(&:to_i)
    end

    alias brep binary_representation

    # Returns a base 10 numeric from the passed array representation
    # @param representation [Array] the representation used to generate the numeric
    # @returns [Integer] the base 10 numeric of the representation.
    def from_binary_rep(representation)
      res = 0
      representation.each_with_index do |bit, idx|
        res += bit * (2**idx)
      end
      res
    end

    alias from_brep from_binary_rep

    # Returned unsigned
    # @param type [Symbol] the type of primitive ths value will be returned as
    def unsigned(type)
      case type
      when :Byte, :byte, :b, :B
        self > 0xFF ? 0xFF : self
      when :Short, :short, :s, :S
        self > 0xFFFF ? 0xFFFF : self
      when :Integer, :Int, :int, :integer, :i, :I
        self > 0xFFFFFFFF ? 0xFFFFFFFF : self
      when :Long, :long, :l, :L
        self > 0xFFFFFFFFFFFFFFFF ? 0xFFFFFFFFFFFFFFFF : self
      else
        self > 0xFFFFFFFF ? 0xFFFFFFFF : self
      end
      0 unless positive?
    end

    # Shorthand
    alias u unsigned

    # Return signed
    # @param type [Symbol] the type of primitive this value will be returned as
    def signed(type)
      case type
      when :Byte, :byte, :b, :B
        adjust(:byte)
      when :Short, :short, :s, :S
        adjust(:short)
      when :Integer, :Int, :int, :integer, :i, :I
        adjust(:integer)
      when :Long, :long, :l, :L
        adjust(:long)
      else
        adjust(:integer)
      end
    end

    # Shorthand
    alias s signed

    def nibble
      adjust(:nibble)
    end

    private

    # adjusts the Integer
    def adjust(type)
      case type
      when :Byte, :byte, :b, :B
        primitive_max = 2**7 - 1
        primitive_min = -2**7
      when :Short, :short, :s, :S
        primitive_max = 2**15 - 1
        primitive_min = -2**15
      when :Integer, :Int, :int, :i, :I
        primitive_max = 2**31 - 1
        primitive_min = -2**31
      when :Long, :long, :l, :L
        primitive_max = 2**63 - 1
        primitive_min = -2**63
      when :Nibble, :nibble, :n, :N
        primitive_max = 2**4 - 1
        primitive_min = -2**4
      else
        primitive_max = 2**31 - 1
        primitive_min = -2**31
      end
      self < -primitive_max ? -1 * (-self & primitive_max) : self
      self > primitive_min ? (self & primitive_max) : self
    end
  end
end