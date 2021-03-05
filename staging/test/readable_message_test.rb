require_relative 'test_helper'

# TODO: Test:
#
# Message#read_string
# Message#read_bytes
# Message#read_bytes_reverse
class ReadableTest < Minitest::Test
  def setup
    # Create a generic stub pool of messages
    @stub_pool = 256.times.each_with_object([]) do |itr, pool|
      content = if RuneRb::Network::FRAME_SIZES[itr].negative?
                  rand(0xffff).times.inject('') { |buf| buf << [rand(0xff)].pack('C') }
                else
                  RuneRb::Network::FRAME_SIZES[itr].times.inject('') { |buf| buf << [rand(0xff)].pack('c') }
                end

      header = { op_code: itr & 0xFF, size: content&.bytesize }
      pool << Message.new('r', header, content) unless RuneRb::Network::FRAME_SIZES[itr].zero?
    end
  end

  # Test the Message#read function
  def test_read
    32.times do
      sample = @stub_pool.sample
      next unless sample.peek.size >= 18

      initial_size = sample.peek.size
      puts "Initial size: #{initial_size}"

      # Read a byte
      puts "STUB BYTE: #{sample.read(:byte, signed: false)}"
      assert_equal(initial_size - 1, sample.peek.size)

      # Read a short
      puts "STUB SHORT: #{sample.read(:short, signed: true, mutation: :STD, order: :BIG)}"
      assert_equal(initial_size - 3, sample.peek.size)

      # Read a medium
      puts "STUB MEDIUM: #{sample.read(:medium, signed: true, mutation: :STD, order: :BIG)}"
      assert_equal(initial_size - 6, sample.peek.size)

      # Read an int
      puts "STUB INT: #{sample.read(:int, signed: true, mutation: :STD, order: :BIG)}"
      assert_equal(initial_size - 10, sample.peek.size)

      # Read a long
      puts "STUB LONG: #{sample.read(:long, signed: true, mutation: :STD, order: :BIG)}"
      assert_equal(initial_size - 18, sample.peek.size)
    end
  end

  # Test that Messages#read(:byte, signed: true):
  # * returns a Integer value >= -255 && <= 255
  # * returns a Integer value that can posses a sign (-)
  def test_read_signed_byte
    32.times do
      # Our stub message
      stub = @stub_pool.sample
      # Ensure the message payload is large enough to test.
      next unless stub.peek.size >= 8

      # The initial size of the payload
      initial_size = stub.peek.size

      # Read 8 signed bytes from the stub message.
      testable_bytes = 8.times.inject([]) { |arr| arr << stub.read(:byte, signed: true) }

      # Test each of the read bytes.
      testable_bytes.each do |byte|
        puts "Testing Signed Byte: #{byte}"
        # Test the byte's range
        assert_equal(true, byte <= 0xff && byte >= -0xff)

        # Test the byte is within range if positive
        assert_equal(true, byte & 0xff == byte) if byte.positive?

        # Test the byte is within range if negative
        assert_equal(true, byte >= -0xff) if byte.negative?
      end

      # Test that 8 bytes were actually read from the payload
      assert_equal(initial_size - 8, stub.peek.size)
    end
  end

  # Test that Message#read(:byte, signed: false):
  # * returns a Integer value >= 0 && <= 255
  def test_read_unsigned_byte
    32.times do
      # Our stub message
      stub = @stub_pool.sample
      # Ensure the message payload is large enough to test.
      next unless stub.peek.size >= 8

      # The initial size of the payload
      initial_size = stub.peek.size

      # Read 8 signed bytes from the stub message.
      testable_bytes = 8.times.inject([]) { |arr| arr << stub.read(:byte, signed: false) }

      # Test each of the read bytes.
      testable_bytes.each do |byte|
        puts "Testing Unsigned Byte: #{byte}"
        # Test the byte's range
        assert_equal(true, byte <= 0xff && byte >= 0)

        # Test the byte is within range if positive
        assert_equal(true, byte & 0xff == byte)
      end

      # Test that 8 bytes were actually read from the payload
      assert_equal(initial_size - 8, stub.peek.size)
    end
  end

  # Test that Message#read(:short, signed: true, mutation: :STD, order: :BIG):
  # * returns a Integer value >= -65535 && <= 65535
  # * returns a Integer value that can posses a sign (-)
  def test_read_signed_short
    32.times do
      # Our stub message
      stub = @stub_pool.sample
      # Ensure the message payload is large enough to test.
      next unless stub.peek.size >= 16

      # The initial size of the payload
      initial_size = stub.peek.size

      # Read 8 signed bytes from the stub message.
      testable_bytes = 8.times.inject([]) { |arr| arr << stub.read(:short, signed: true, mutation: :STD, order: :BIG) }

      # Test each of the read bytes.
      testable_bytes.each do |short|
        puts "Testing Signed Short: #{short}"
        # Test the byte's range
        assert_equal(true, short <= 0xffff && short >= -0xffff)

        # Test the byte is within range if positive
        assert_equal(true, short & 0xffff == short) if short.positive?

        # Test the byte is within range if negative
        assert_equal(true, short >= -0xffff) if short.negative?
      end

      # Test that 8 bytes were actually read from the payload
      assert_equal(initial_size - 16, stub.peek.size)
    end
  end

  # Test that Message#read(:short, signed: true, mutation: :STD, order: :BIG):
  # * returns a Integer value >= 0 && <= 65535
  def test_read_unsigned_short
    32.times do
      # Our stub message
      stub = @stub_pool.sample
      # Ensure the message payload is large enough to test.
      next unless stub.peek.size >= 16

      # The initial size of the payload
      initial_size = stub.peek.size

      # Read 8 signed bytes from the stub message.
      testable_bytes = 8.times.inject([]) { |arr| arr << stub.read(:short, signed: false, mutation: :STD, order: :BIG) }

      # Test each of the read bytes.
      testable_bytes.each do |short|
        puts "Testing Unsigned Short: #{short}"
        # Test the byte's range
        assert_equal(true, short <= 0xffff && short >= 0)

        # Test the byte is within range if positive
        assert_equal(true, short & 0xffff == short)
      end

      # Test that 8 bytes were actually read from the payload
      assert_equal(initial_size - 16, stub.peek.size)
    end
  end

  # Test that Messages#read(:int, signed: true, mutation: :STD, order: :BIG):
  # * returns a Integer value >= 4294967295 && <= -4294967295
  # * returns a Integer value that can posses a sign (-)
  def test_read_int
    32.times do
      # Our stub message
      stub = @stub_pool.sample
      # Ensure the message payload is large enough to test.
      next unless stub.peek.size >= 32

      # The initial size of the payload
      initial_size = stub.peek.size

      # Read 8 signed integers from the stub message.
      testable_integers = 8.times.inject([]) { |arr| arr << stub.read(:int, signed: true, mutation: :STD, order: :BIG) }

      # Test each of the read integers.
      testable_integers.each do |int|
        puts "Testing Signed Integer: #{int}"
        # Test the byte's range
        assert_equal(true, int <= 0xffffffff && int >= -0xffffffff)

        # Test the byte is within range if positive
        assert_equal(true, int & 0xffffffff == int) if int.positive?

        # Test the byte is within range if negative
        assert_equal(true, int >= -0xffffffff) if int.negative?
      end

      # Test that 8 bytes were actually read from the payload
      assert_equal(initial_size - 32, stub.peek.size)
    end
  end

  # Test that Message#read(:long, signed: true, mutation: :STD, order: :BIG):
  # * returns a Integer value >= 18446744073709551615 && <= -18446744073709551615
  # * returns a Integer value that can posses a sign (-)
  def test_read_long
    32.times do
      # Our stub message
      stub = @stub_pool.sample
      # Ensure the message payload is large enough to test.
      next unless stub.peek.size >= 64

      # The initial size of the payload
      initial_size = stub.peek.size

      # Read 8 signed integers from the stub message.
      testable_longs = 8.times.inject([]) { |arr| arr << stub.read(:long, signed: true, mutation: :STD, order: :BIG) }

      # Test each of the read integers.
      testable_longs.each do |long|
        puts "Testing Signed Long: #{long}"
        # Test the byte's range
        assert_equal(true, long <= 0xffffffffffffffff && long >= -0xffffffffffffffff)

        # Test the byte is within range if positive
        assert_equal(true, long & 0xffffffffffffffff == long) if long.positive?

        # Test the byte is within range if negative
        assert_equal(true, long >= -0xffffffffffffffff) if long.negative?
      end

      # Test that 8 bytes were actually read from the payload
      assert_equal(initial_size - 64, stub.peek.size)
    end
  end

  # Test that Message#read(:medium, signed: true, mutation: :STD, order: :BIG)
  # * returns a Integer value >= 16777215 && <= -16777215
  # * returns a Integer value that can posses a sign (-)
  def test_read_medium
    32.times do
      # Our stub message
      stub = @stub_pool.sample
      # Ensure the message payload is large enough to test.
      next unless stub.peek.size >= 24

      # The initial size of the payload
      initial_size = stub.peek.size

      # Read 8 signed integers from the stub message.
      testable_longs = 8.times.inject([]) { |arr| arr << stub.read(:medium, signed: true, mutation: :STD, order: :BIG) }

      # Test each of the read integers.
      testable_longs.each do |medium|
        puts "Testing Signed Medium: #{medium}"
        # Test the byte's range
        assert_equal(true, medium <= 0xffffff && medium >= - 0xffffff)

        # Test the byte is within range if positive
        assert_equal(true, medium & 0xffffff == medium) if medium.positive?

        # Test the byte is within range if negative
        assert_equal(true, medium >= -0xffffff) if medium.negative?
      end

      # Test that 8 bytes were actually read from the payload
      assert_equal(initial_size - 24, stub.peek.size)
    end
  end
end
