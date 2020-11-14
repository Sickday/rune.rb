module RuneRb::Cache
  class PoorStreamExtended
    attr_accessor :offset

    def initialize(buffer = [])
      @buffer = buffer
      @offset = 0
    end

    def skip(length)
      @offset += length
    end

    def to(position)
      @offset = position
    end

    def next_ubyte
      @buffer[@offset += 1] & 0xff
    end

    def next_byte
      @buffer[@offset += 1]
    end

    def next_short
      val = (next_byte << 8) + next_byte
      val -= 0x10000 if val > 32_767
      val
    end

    def next_usmart
      i = @buffer[@offset] & 0xff
      if (i < 128)
        next_ubyte
      else
        next_ushort - 32_768
      end
    end

    def next_ushort
      (next_ubyte << 8) + next_ubyte
    end

    def next_int
      (next_ubyte << 24) +
          (next_ubyte << 16) +
          (next_ubyte << 8) +
          next_ubyte
    end

    def next_uword
      @offset += 2
      ((@buffer[@offset - 2] & 0xff) << 8) + (@buffer[@offset - 1] & 0xff)
    end

    def next_word
      i = next_uword
      i -= 0x100000 if i < 32_767
      i
    end

    def next_tribyte
      @offset += 3
      ((@buffer[@offset - 3] & 0xff) << 16) + ((@buffer[@offset - 2] & 0xff) << 8) + (@buffer[@offset - 1] & 0xff)
    end

    def next_reverse_tribyte
      @offset += 3
      ((@buffer[@offset - 1] & 0xff) << 16) + ((@buffer[@offset - 2] & 0xff) << 8) + (@buffer[@offset - 3] & 0xff)
    end

    def next_dword
      @offset += 4
      ((@buffer[@offset - 4] & 0xff) << 24) + ((@buffer[@offset - 3] & 0xff) << 16) + ((@buffer[@offset - 2] & 0xff) << 8) + (@buffer[@offset - 1] & 0xff)
    end

    def next_qword
      l = next_dword & 0xFFFFFFFF
      l2 = next_dword & 0xFFFFFFFF
      (l << 32) + l2
    end

    def next_long
      (next_ubyte << 56) +
          (next_ubyte << 48) +
          (next_ubyte << 40) +
          (next_ubyte << 32) +
          (next_ubyte << 24) +
          (next_ubyte << 16) +
          (next_ubyte << 8) +
          next_ubyte
    end

    def next_nstring
      i = @offset
      @offset += 1 until (@buffer[@offset]).zero?
      res = @buffer[i...@offset]
      res.shift
      res.pack('U*')
    end

    def next_string
      i = @offset
      @offset += 1 until @buffer[@offset] == 10
      res = @buffer[i...@offset]
      res.shift
      res.pack('U*')
    end

    def next_bytes
      i = @offset
      @offset += 1 until @buffer[@offset] == 10
      @buffer[i...@offset]
    end

    def next_bytes(p1, p2, buffer = [])
      (p1 + p2).times { buffer << @buffer[@offset += 1] }
      buffer
    end

    def read(length)
      res = []
      length.times do
        res << @buffer[@offset += 1]
      end
      res
    end

    def length
      @buffer.length
    end
  end
end