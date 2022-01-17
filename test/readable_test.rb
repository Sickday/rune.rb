require_relative 'test_helper'

class ReadableBufferTest < Minitest::Test

  def test_read_unsigned_byte
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_byte = stub_readable.read(type: :byte, signed: false)
      puts "Read Unsigned Byte: #{read_byte}"

      assert_equal(true, read_byte.is_a?(Integer))
      assert_equal(true, read_byte <= 0xFF)
      assert_equal(true, read_byte >= 0)
    end
  end

  def test_read_signed_byte
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_signed_byte = stub_readable.read(type: :byte, signed: true)
      puts "Read Signed Byte: #{read_signed_byte}"

      assert_equal(true, read_signed_byte.is_a?(Integer))
      assert_equal(true, read_signed_byte <= 0xFF)
      assert_equal(true, read_signed_byte >= -0xFF)
    end
  end

  def test_read_unsigned_short
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_short = stub_readable.read(type: :short, signed: false)
      puts "Read Unsigned Short: #{read_short}"

      assert_equal(true, read_short.is_a?(Integer))
      assert_equal(true, read_short <= 0xFFFF)
      assert_equal(true, read_short >= 0)
    end
  end

  def test_read_signed_short
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_signed_short = stub_readable.read(type: :short, signed: true)
      puts "Read Signed Short: #{read_signed_short}"

      assert_equal(true, read_signed_short.is_a?(Integer))
      assert_equal(true, read_signed_short <= 0xFFFF)
      assert_equal(true, read_signed_short >= -0xFFFF)
    end
  end

  def test_read_signed_medium
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_signed_medium = stub_readable.read(type: :medium, signed: true)
      puts "Read Signed Medium: #{read_signed_medium}"

      assert_equal(true, read_signed_medium.is_a?(Integer))
      assert_equal(true, read_signed_medium <= 0xFFFFFF)
      assert_equal(true, read_signed_medium >= -0xFFFFFF)
    end
  end

  def test_read_unsigned_medium
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_medium = stub_readable.read(type: :medium, signed: false)
      puts "Read Unsigned Medium: #{read_medium}"

      assert_equal(true, read_medium.is_a?(Integer))
      assert_equal(true, read_medium <= 0xFFFFFF)
      assert_equal(true, read_medium >= 0)
    end
  end

  def test_read_unsigned_integer
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_integer = stub_readable.read(type: :int, signed: false)
      puts "Read Unsigned Integer: #{read_integer}"

      assert_equal(true, read_integer.is_a?(Integer))
      assert_equal(true, read_integer <= 0xFFFFFFFF)
      assert_equal(true, read_integer >= 0)
    end
  end

  def test_read_signed_integer
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_signed_integer = stub_readable.read(type: :int, signed: true)
      puts "Read Signed Integer: #{read_signed_integer}"

      assert_equal(true, read_signed_integer.is_a?(Integer))
      assert_equal(true, read_signed_integer <= 0xFFFFFFFF)
      assert_equal(true, read_signed_integer >= -0xFFFFFFFF)
    end
  end

  def test_read_unsigned_long
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_long = stub_readable.read(type: :long, signed: false)
      puts "Read Unsigned Long: #{read_long}"

      assert_equal(true, read_long.is_a?(Integer))
      assert_equal(true, read_long <= 0xFFFFFFFFFFFFFFFFF)
      assert_equal(true, read_long >= 0)
    end
  end

  def test_read_signed_long
    rand(0xFF).times do
      stub_readable = RuneRb::Network::Buffer.new('r')
      stub_readable.push(JUNK_DATA_FACTORY.call)

      read_long = stub_readable.read(type: :long, signed: true)
      puts "Read Signed Long: #{read_long}"

      assert_equal(true, read_long.is_a?(Integer))
      assert_equal(true, read_long <= 0xFFFFFFFFFFFFFFFFF)
      assert_equal(true, read_long >= -0xFFFFFFFFFFFFFFFF)
    end
  end
end