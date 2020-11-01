require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'

require_relative '../app/rune'

using RuneRb::Patches::StringOverrides

SIZES = { 4 => 'c', 8 => 'n', 16 => 'l', 32 => 'q' }.freeze # Pre-defined sizes for primitives we'll be working with (byte, short, integer, long) and their packing directives
Assets = Struct.new(:sample_pool, :to_read, :original_size)
# Define a string-based buffer
# Populate the buffer with a random assortment of different primitive types.

describe String do
  before(:each) do
    @string_buffer = ''
    0xFFF.times do
      inf = SIZES.to_a.sample
      @string_buffer << [rand(1 << inf.first)].pack(inf.last)
    end
    @assets = Assets.new([], rand(1...0xFF), @string_buffer.bytesize)
  end

  describe '#next_byte' do
    it 'returns the next byte' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_byte }

      assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
    end
  end

  describe '#next_bytes' do
    it 'returns the next x bytes' do
      @assets[:sample_pool] = @string_buffer.next_bytes(@assets[:to_read])

      assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
    end
  end

  describe '#byte_from' do
    it 'returns the next byte from a given position' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.byte_from(64) }

      assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
    end
  end

  describe '#bytes_from' do
    it 'returns x bytes from a given position' do
      @assets[:sample_pool] = @string_buffer.bytes_from(64, @assets[:to_read])

      assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
    end
  end

  describe '#next_short' do
    it 'returns the next short' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_short }

      assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
    end
  end

  describe '#next_shorts' do
    it 'returns the next x shorts' do
      @assets[:sample_pool] = @string_buffer.next_shorts(@assets[:to_read])

      assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
    end
  end

  describe '#short_from' do
    it 'returns the next short from a given position' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.short_from(64) }

      assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
    end
  end

  describe '#shorts_from' do
    it 'returns x shorts from the given offset' do
      @assets[:sample_pool] = @string_buffer.shorts_from(64, @assets[:to_read])

      assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
    end
  end

  describe '#next_int' do
    it 'returns the next integer' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_int }

      assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
    end
  end

  describe '#next_ints' do
    it 'returns the next x integers' do
      @assets[:sample_pool] = @string_buffer.next_ints(@assets[:to_read])

      assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
    end
  end

  describe '#int_from' do
    it 'returns the int from the given offset' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.int_from(64) }

      assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
    end
  end

  describe '#ints_from' do
    it 'returns the next x integers from a given offset' do
      @assets[:sample_pool] = @string_buffer.ints_from(64, @assets[:to_read])

      assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
    end
  end

  describe '#next_long' do
    it 'returns the next long' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_long }

      assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
    end
  end

  describe '#next_longs' do
    it 'returns the next x longs' do
      @assets[:sample_pool] = @string_buffer.next_longs(@assets[:to_read])

      assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
    end
  end

  describe '#long_from' do
    it 'returns the next long from the given offset' do
      @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.long_from(64) }

      assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
    end
  end

  describe '#longs_from' do
    it 'returns the next x longs from the given offset' do
      @assets[:sample_pool] = @string_buffer.longs_from(64, @assets[:to_read])

      assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
      assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
    end
  end
end

# Q: When describing an object that has multiple ways of returning output with strict specifications, how should you approach the description of it's functions? Is it ok to validate the output against it's specifications in every description of the object's functions?