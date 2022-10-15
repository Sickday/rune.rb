require_relative 'test_helper'

# Test for String refinements (RuneRb::Patches::StringOverrides).
# Ensures a String-based buffer/stream/io object behaves as expected while using my refinements.
class StringRefinementsTest < Minitest::Test
  using RuneRb::Patches::StringRefinements # Use the refinement object we're testing.

  SIZES = { 4 => 'c', 8 => 'n', 16 => 'l', 32 => 'q' }.freeze # Pre-defined sizes for primitives we'll be working with (byte, short, integer, long) and their packing directives
  STRINGS = %w[Pat Jaime Jason Sen].freeze
  Assets = Struct.new(:sample_pool, :to_read, :original_size, :string)

  # Define a string-based buffer
  # Populate the buffer with a random assortment of different primitive types.
  # @return [Struct] a hash containing
  def setup
    @string_buffer = ''
    0xFFF.times do
      inf = SIZES.to_a.sample
      @string_buffer << [rand(1 << inf.first)].pack(inf.last)
    end
    @assets = Assets.new([], rand(1...0xFF), @string_buffer.bytesize, STRINGS.sample)
  end

  # Test the String#next_byte function
  #
  # ASSERTIONS:
  # * Test that each byte from our sample pool does not exceed the bounds of a byte
  # * Test that the buffer's new size is equal to the original size minus the amount of read bytes
  def test_next_byte
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_byte }

    assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
  end

  # Test the String#next_bytes function
  #
  # ASSERTIONS:
  # * Test that each byte from our sample pool does not exceed the bounds of a byte
  # * Test that the buffer's new size is equal to the original size minus the amount of read bytes
  def test_next_bytes
    @assets[:sample_pool] = @string_buffer.next_bytes(@assets[:to_read])

    assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
  end

  # Test the String#byte_from function
  #
  # ASSERTIONS:
  # * Test that each byte from our sample pool does not exceed the bounds of a byte
  # * Test that the buffer's new size is equal to the original size minus the amount of read bytes
  def test_byte_from
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.byte_from(64) }

    assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
  end

  # Test the String#bytes_from function
  #
  # ASSERTIONS:
  # * Test that each short from our sample pool does not exceed the bounds of a short
  # * Test that the buffer's new size is equal to the original size minus the amount of read shorts.
  def test_bytes_from
    @assets[:sample_pool] = @string_buffer.bytes_from(64, @assets[:to_read])

    assert(@assets[:sample_pool].all? { |byte| byte <= 0xFF && byte >= -0xFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - @assets[:to_read])
  end

  # Test the String#next_short function
  #
  # ASSERTIONS:
  # * Test that each short from our sample pool does not exceed the bounds of a short
  # * Test that the buffer's new size is equal to the original size minus the amount of read shorts
  def test_next_short
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_short }

    assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
  end

  # Test the String#next_shorts function
  #
  # ASSERTIONS:
  # * Test that each short from our sample pool does not exceed the bounds of a short
  # * Test that the buffer's new size is equal to the original size minus the amount of read shorts
  def test_next_shorts
    @assets[:sample_pool] = @string_buffer.next_shorts(@assets[:to_read])

    assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
  end

  # Test the String#short_from function
  #
  # ASSERTIONS:
  # * Test that each short from our sample pool does not exceed the bounds of a short
  # * Test that the buffer's new size is equal to the original size minus the amount of read shorts
  def test_short_from
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.short_from(64) }

    assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
  end

  # Test the String#shorts_from function
  #
  # ASSERTIONS:
  # * Test that each short from our sample pool does not exceed the bounds of a short
  # * Test that the buffer's new size is equal to the original size minus the amount of read shorts
  def test_shorts_from
    @assets[:sample_pool] = @string_buffer.shorts_from(64, @assets[:to_read])

    assert(@assets[:sample_pool].all? { |short| short <= 0xFFFF && short >= -0xFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 2))
  end

  # Test the String#next_int function
  #
  # ASSERTIONS:
  # * Test that each integer from our sample pool does not exceed the bounds of a integer
  # * Test that the buffer's new size is equal to the original size minus the amount of read integers
  def test_next_int
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_int }

    assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
  end

  # Test the String#next_ints function
  #
  # ASSERTIONS:
  # * Test that each integer from our sample pool does not exceed the bounds of a integer
  # * Test that the buffer's new size is equal to the original size minus the amount of read integers
  def test_next_ints
    @assets[:sample_pool] = @string_buffer.next_ints(@assets[:to_read])

    assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
  end

  # Test the String#int_from function
  #
  # ASSERTIONS:
  # * Test that each integer from our sample pool does not exceed the bounds of a integer
  # * Test that the buffer's new size is equal to the original size minus the amount of read integers
  def test_int_from
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.int_from(64) }

    assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
  end

  # Test the String#ints_from function
  #
  # ASSERTIONS:
  # * Test that each integer from our sample pool does not exceed the bounds of a integer
  # * Test that the buffer's new size is equal to the original size minus the amount of read integers
  def test_ints_from
    @assets[:sample_pool] = @string_buffer.ints_from(64, @assets[:to_read])

    assert(@assets[:sample_pool].all? { |int| int <= 0xFFFFFFFF && int >= -0xFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 4))
  end

  # Test the String#next_long function
  #
  # ASSERTIONS:
  # * Test that each long from our sample pool does not exceed the bounds of a long
  # * Test that the buffer's new size is equal to the original size minus the amount of read longs
  def test_next_long
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.next_long }

    assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
  end

  # Test the String#next_longs function
  #
  # ASSERTIONS:
  # * Test that each long from our sample pool does not exceed the bounds of a long
  # * Test that the buffer's new size is equal to the original size minus the amount of read longs
  def test_next_longs
    @assets[:sample_pool] = @string_buffer.next_longs(@assets[:to_read])

    assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
  end

  # Test the String#long_from function
  #
  # ASSERTIONS:
  # * Test that each long from our sample pool does not exceed the bounds of a long
  # * Test that the buffer's new size is equal to the original size minus the amount of read longs
  def test_long_from
    @assets[:to_read].times { @assets[:sample_pool] << @string_buffer.long_from(64) }

    assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
  end

  # Test the String#longs_from function
  #
  # ASSERTIONS:
  # * Test that each long from our sample pool does not exceed the bounds of a long
  # * Test that the buffer's new size is equal to the original size minus the amount of read longs
  def test_longs_from
    @assets[:sample_pool] = @string_buffer.longs_from(64, @assets[:to_read])

    assert(@assets[:sample_pool].all? { |long| long <= 0xFFFFFFFFFFFFFFFF && long >= -0xFFFFFFFFFFFFFFFF })
    assert_equal(@string_buffer.bytesize, @assets[:original_size] - (@assets[:to_read] * 8))
  end

  # Test the String#to_base37 function
  #
  # ASSERTIONS:
  # * Test that a String converted to a base37 numeric is actually a base37 numeric (numeric % 37 == 0)
  def test_to_base37
    assert(@assets[:string].to_base37 % 37, 0)
  end

  # Test the String#from_base37 function
  #
  # ASSERTIONS:
  # * Test that a String built from a base37 numeric is the same string that would generate the base37 numeric.
  # * Test that a String with existing text will return itself instead of parsing a base37 numeric unless the String is empty
  def test_from_base37
    b37 = @assets[:string].to_base37
    assert(''.from_base37(b37), @assets[:string])
    assert_equal('string_with_text', 'string_with_text'.from_base37(b37))
  end
end
