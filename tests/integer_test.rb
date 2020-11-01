require_relative '../app/rune'
require 'minitest/pride'
require 'minitest/autorun'

# Testing for integer overrides
class IntegerOverrideTest < Minitest::Test
  using RuneRb::Patches::IntegerOverrides

  test_num_one = 250 # A value that does not exceed a byte's max value (0xff)
  test_num_two = 260 # A value that exceeds a byte's max value (0xFF)



  def test_signed_and_unsigned_byte_values
    assert(test_num_two.unsigned(:b).zero? == false) # Test that an unsigned byte 'cast' to the second number would equal 0 as the value exceeds the bounds of a byte (0xff)
    assert_equal(250, test_num_one.unsigned(:b)) # Test that the value is unchanged as the value is already unsigned and still within the range of a byte (0xff)

    original_test_one = test_num_one
    test_num_one += 32
    assert_equal((original_test_one + 32) - 256, test_num_one.unsigned(:b)) # Test the wrapping behavior of an overflowed integer.
  end
end