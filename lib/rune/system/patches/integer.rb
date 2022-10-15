# A module adding overflow functions to integers to mimic the behavior of Java primitive overflow behavior.
module RuneRb::Patches::IntegerRefinements

  refine Integer do

    # Returns a binary representation in the form of an array of 1's and 0's in their respective digits.
    # @return [Array] the binary representation
    def binary_representation
      to_s(2).chars.map(&:to_i)
    end

    alias_method :brep, :binary_representation

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

    alias_method :from_brep, :from_binary_rep

    # Adjusts the value of the Integer to be unsigned.
    # @param type [Symbol] the type of primitive the value will be returned as
    def unsigned(type)
      return 0 if negative?
      case type
      when :Byte, :byte, :b, :B then to_i > 0xFF ? 0xFF : to_i
      when :Short, :short, :s, :S then to_i > 0xFFFF ? 0xFFFF : to_i
      when :Integer, :Int, :int, :integer, :i, :I then to_i > 0xFFFFFFFF ? 0xFFFFFFFF : to_i
      when :Long, :long, :l, :L then to_i > 0xFFFFFFFFFFFFFFFF ? 0xFFFFFFFFFFFFFFFF : to_i
      else unsigned(:int)
      end
    end

    alias_method :u, :unsigned

    # Adjusts the value of the Integer to be signed.
    # @param type [Symbol] the type of primitive the value will be returned as
    def signed(type)
      case type
      when :Byte, :byte, :b, :B then adjust(:byte)
      when :Short, :short, :s, :S then adjust(:short)
      when :Integer, :Int, :int, :integer, :i, :I then adjust(:integer)
      when :Long, :long, :l, :L then adjust(:long)
      else adjust(:integer)
      end
    end

    alias_method :s, :signed

    def nibble
      adjust(:nibble)
    end

    # Returns a string with a formatted representation of the Integer as a timestamp.
    def to_ftime
      mm, ss = divmod(60)
      hh, mm = mm.divmod(60)
      dd, hh = hh.divmod(24)
      format('%d days, %d hours, %d minutes, and %d seconds', dd, hh, mm, ss)
    end

    private

    # Adjusts the integer based on the passed type
    # @param type [Symbol] the type of adjustment to make to the integer.
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
        primitive_max = 2**4
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
