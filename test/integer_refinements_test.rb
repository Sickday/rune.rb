require_relative 'test_helper'

# Testing for RuneRb::System::Patches::IntegerRefinements refinements
class IntegerRefinementsTest < Minitest::Test
  using RuneRb::Patches::IntegerRefinements

  # A byte's max value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Byte.html#MAX_VALUE
  BYTE_MAX_VALUE = 2**7 - 1

  # A byte's min value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Byte.html#MIN_VALUE
  BYTE_MIN_VALUE = -2**7

  # A short's max value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Short.html#MAX_VALUE
  SHORT_MAX_VALUE = 2**15 - 1

  # A short's min value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Short.html#MIN_VALUE
  SHORT_MIN_VALUE = -2**15

  # A integer's max value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Integer.html#MAX_VALUE
  INTEGER_MAX_VALUE = 2**31 - 1

  # A integer's min value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Integer.html#MIN_VALUE
  INTEGER_MIN_VALUE = -2**31

  # A long's max value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Long.html#MAX_VALUE
  LONG_MAX_VALUE = 2**63 - 1

  # A long's min value according to oracle documentation:
  # https://docs.oracle.com/javase/8/docs/api/java/lang/Long.html#MIN_VALUE
  LONG_MIN_VALUE = -2**63

  def setup
    @unsigned = { bytes: [], shorts: [], ints: [], longs: [] }
    @signed = { bytes: [], shorts: [], ints: [], longs: [] }
    @overflowed = { bytes: [], shorts: [], ints: [], longs: [] }

    rand(0xffff).times do
      # Unsigned
      @unsigned[:bytes] << rand(BYTE_MAX_VALUE).unsigned(:byte)
      @unsigned[:shorts] << rand(SHORT_MAX_VALUE).unsigned(:short)
      @unsigned[:ints] << rand(INTEGER_MAX_VALUE).unsigned(:int)
      @unsigned[:longs] << rand(LONG_MAX_VALUE).unsigned(:long)

      # Signed
      @signed[:bytes] << rand(BYTE_MIN_VALUE..BYTE_MAX_VALUE).signed(:byte)
      @signed[:shorts] << rand(SHORT_MIN_VALUE..SHORT_MAX_VALUE).signed(:short)
      @signed[:ints] << rand(INTEGER_MIN_VALUE..INTEGER_MAX_VALUE).signed(:int)
      @signed[:longs] << rand(LONG_MIN_VALUE..LONG_MAX_VALUE).signed(:long)

      # Overflowed
      @overflowed[:bytes] << rand(BYTE_MAX_VALUE..BYTE_MAX_VALUE * 2)
      @overflowed[:shorts] << rand(SHORT_MAX_VALUE..SHORT_MAX_VALUE * 2)
      @overflowed[:ints] << rand(INTEGER_MAX_VALUE..INTEGER_MAX_VALUE * 2)
      @overflowed[:longs] << rand(LONG_MAX_VALUE..LONG_MAX_VALUE * 2)
    end
  end

  def test_unsigned_bytes
    @unsigned[:bytes].each do |byte|
      # Applying a mask of 0xff will return a unsigned representation of the numeric.
      # All these values are meant to be unsigned already, they should all return themselves.
      assert_equal(byte & 0xff, byte)

      # The byte must be either 0 or positive yet still less than or equal to the max value for a byte.
      assert((byte.positive? || byte.zero?) && byte <= BYTE_MAX_VALUE, true)
    end
  end

  def test_unsigned_shorts
    @unsigned[:shorts].each do |short|
      # Applying a mask of 0xffff will return a unsigned representation of the numeric.
      # All these values are meant to be unsigned already, they should all return themselves.
      assert_equal(short & 0xffff, short)

      # The byte must be either 0 or positive yet still less than or equal to the max value for a short.
      assert((short.positive? || short.zero?) && short <= SHORT_MAX_VALUE, true)
    end
  end

  def test_unsigned_integers
    @unsigned[:ints].each do |int|
      # Applying a mask of 0xffffffff will return a unsigned representation of the numeric.
      # All these values are meant to be unsigned already, they should all return themselves.
      assert_equal(int & 0xffffffff, int)

      # The int must be either 0 or positive yet still less than or equal to the max value for a int.
      assert((int.positive? || int.zero?) && int <= INTEGER_MAX_VALUE, true)
    end
  end

  def test_unsigned_longs
    @unsigned[:longs].each do |long|
      # Applying a mask of 0xffffffffffffffff will return a unsigned representation of the numeric.
      # All these values are meant to be unsigned already, they should all return themselves.
      assert_equal(long & 0xffffffffffffffff, long)

      # The long must be either 0 or positive yet still less than or equal to the max value for a long.
      assert((long.positive? || long.zero?) && long <= LONG_MAX_VALUE, true)
    end
  end

  def test_signed_bytes
    @signed[:bytes].each do |byte|
      # Ensure the byte is within the bounds of a signed byte.
      assert(byte >= BYTE_MIN_VALUE, true)
      assert(byte <= BYTE_MAX_VALUE, true)
    end
  end

  def test_signed_shorts
    @signed[:shorts].each do |short|
      # Ensure the short is within the bounds of a signed short.
      assert(short >= SHORT_MIN_VALUE, true)
      assert(short <= SHORT_MAX_VALUE, true)
    end
  end

  def test_signed_integers
    @signed[:ints].each do |int|
      # Ensure the integer is within the bounds of a signed integer.
      assert(int >= INTEGER_MIN_VALUE, true)
      assert(int <= INTEGER_MAX_VALUE, true)
    end
  end

  def test_signed_longs
    @signed[:longs].each do |long|
      # Ensure the long is within the bounds of a signed long.
      assert(long >= LONG_MIN_VALUE, true)
      assert(long <= LONG_MAX_VALUE, true)
    end
  end
end
