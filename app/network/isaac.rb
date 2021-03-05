# Copyright (c) 2020, Patrick W.
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

module RuneRb::Network
  # An implementation of an ISAAC cipher used to generate random numbers for message interchange.
  class ISAAC
    using RuneRb::System::Patches::IntegerRefinements

    # Called when a new ISAAC Cipher is created.
    def initialize(seed)
      @aa = 0
      @bb = 0
      @cc = 0
      @mm = []
      @randrsl = Array.new(256, 0)

      seed.each_with_index do |element, i|
        @randrsl[i] = element
      end

      randinit
    end

    # Gets the next random value.
    # If 256 cycles have occurred, the results array is regenerated.
    def next_value
      if @randcnt.zero?
        isaac
        @randcnt = 256
      end
      @randcnt -= 1
      @randrsl[@randcnt].signed(:i)
    end

    private

    # Generates 256 new results.
    def isaac
      r = @randrsl
      aa = @aa
      @cc += 1
      bb = (@bb + (@cc)) & 0xffffffff
      x = y = 0

      (0...256).step(4) do |i|
        x = @mm[i]
        aa = ((aa ^ (aa << 13)) + @mm[(i + 128) & 0xff])
        aa &= 0xffffffff
        @mm[i] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
        x = @mm[i + 1]
        aa = ((aa ^ (0x03ffffff & (aa >> 6))) + @mm[(i + 1 + 128) & 0xff])
        aa &= 0xffffffff
        @mm[i + 1] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i + 1] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
        x = @mm[i + 2]
        aa = ((aa ^ (aa << 2)) + @mm[(i + 2 + 128) & 0xff])
        aa &= 0xffffffff
        @mm[i + 2] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i + 2] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
        x = @mm[i + 3]
        aa = ((aa ^ (0x0000ffff & (aa >> 16))) + @mm[(i + 3 + 128) & 0xff])
        aa &= 0xffffffff
        @mm[i + 3] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i + 3] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
      end

      @bb = bb
      @aa = aa
    end

    # Initializes the memory array.
    def randinit
      c = d = e = f = g = h = j = k = 0x9e3779b9
      r = @randrsl

      4.times do
        c = c ^ (d << 11)
        f += c
        d += e
        d = d ^ (0x3fffffff & (e >> 2))
        g += d
        e += f
        e = e ^ (f << 8)
        h += e
        f += g
        f = f ^ (0x0000ffff & (g >> 16))
        j += f
        g += h
        g = g ^ (h << 10)
        k += g
        h += j
        h = h ^ (0x0fffffff & (j >> 4))
        c += h
        j += k
        j = j ^ (k << 8)
        d += j
        k += c
        k = k ^ (0x007fffff & (c >> 9))
        e += k
        c += d
      end

      (0...256).step(8) do |i|
        c += r[i]
        d += r[i + 1]
        e += r[i + 2]
        f += r[i + 3]
        g += r[i + 4]
        h += r[i + 5]
        j += r[i + 6]
        k += r[i + 7]
        c = c ^ (d << 11)
        f += c
        d += e
        d = d ^ (0x3fffffff & (e >> 2))
        g += d
        e += f
        e = e ^ (f << 8)
        h += e
        f += g
        f = f ^ (0x0000ffff & (g >> 16))
        j += f
        g += h
        g = g ^ (h << 10)
        k += g
        h += j
        h = h ^ (0x0fffffff & (j >> 4))
        c += h
        j += k
        j = j ^ (k << 8)
        d += j
        k += c
        k = k ^ (0x007fffff & (c >> 9))
        e += k
        c += d
        @mm[i] = c
        @mm[i + 1] = d
        @mm[i + 2] = e
        @mm[i + 3] = f
        @mm[i + 4] = g
        @mm[i + 5] = h
        @mm[i + 6] = j
        @mm[i + 7] = k
      end

      (0...256).step(8) do |i|
        c += @mm[i]
        d += @mm[i + 1]
        e += @mm[i + 2]
        f += @mm[i + 3]
        g += @mm[i + 4]
        h += @mm[i + 5]
        j += @mm[i + 6]
        k += @mm[i + 7]
        c = c ^ (d << 11)
        f += c
        d += e
        d = d ^ (0x3fffffff & (e >> 2))
        g += d
        e += f
        e = e ^ (f << 8)
        h += e
        f += g
        f = f ^ (0x0000ffff & (g >> 16))
        j += f
        g += h
        g = g ^ (h << 10)
        k += g
        h += j
        h = h ^ (0x0fffffff & (j >> 4))
        c += h
        j += k
        j = j ^ (k << 8)
        d += j
        k += c
        k = k ^ (0x007fffff & (c >> 9))
        e += k
        c += d
        @mm[i] = c
        @mm[i + 1] = d
        @mm[i + 2] = e
        @mm[i + 3] = f
        @mm[i + 4] = g
        @mm[i + 5] = h
        @mm[i + 6] = j
        @mm[i + 7] = k
      end

      isaac
      @randcnt = 256
    end
  end
end
