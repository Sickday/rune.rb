require_relative 'test_helper'

class WriteableBufferTest < Minitest::Test

  def test_write_byte_add_sub
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :byte, mutation: :ADD) }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :byte, mutation: :SUB))
      end

      puts "TESTING WRITE UNSIGNED BYTE ADD/SUB, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE UNSIGNED BYTE ADD/SUB, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_byte_sub_add
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :byte, mutation: :SUB) }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :byte, mutation: :ADD, signed: true))
      end

      puts "TESTING WRITE UNSIGNED BYTE SUB/ADD, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE UNSIGNED BYTE SUB/ADD, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_byte_neg
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :byte, mutation: :NEG) }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :byte, mutation: :NEG, signed: true))
      end

      puts "TESTING WRITE UNSIGNED BYTE NEG, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE UNSIGNED BYTE NEG, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_short_be
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :short, order: 'BIG') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :short, order: 'BIG'))
      end

      puts "TESTING WRITE SHORT BIG ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE SHORT BIG ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_short_le
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :short, order: 'LITTLE') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :short, order: 'LITTLE'))
      end

      puts "TESTING WRITE SHORT LITTLE ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE SHORT LITTLE ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_medium_be
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xfff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :medium, order: 'BIG') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :medium, order: 'BIG'))
      end

      puts "TESTING WRITE MEDIUM BIG ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE MEDIUM BIG ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_medium_me
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xfff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :medium, order: 'MIDDLE') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :medium, order: 'MIDDLE'))
      end

      puts "TESTING WRITE MEDIUM MIDDLE ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE MEDIUM MIDDLE ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_medium_le
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xfff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :medium, order: 'LITTLE') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :medium, order: 'LITTLE'))
      end

      puts "TESTING WRITE MEDIUM LITTLE ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE MEDIUM LITTLE ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_int_ime
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffffffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :int, order: 'INVERSE_MIDDLE') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :int, order: 'INVERSE_MIDDLE'))
      end

      puts "TESTING WRITE INT INVERSE MIDDLE ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE INT INVERSE MIDDLE ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_int_me
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffffffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :int, order: 'MIDDLE') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :int, order: 'MIDDLE'))
      end

      puts "TESTING WRITE INT MIDDLE ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE INT MIDDLE ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_int_le
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffffffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :int, order: 'LITTLE') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :int, order: 'LITTLE'))
      end

      puts "TESTING WRITE INT LITTLE ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE INT LITTLE ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_int_be
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffffffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :int, order: 'BIG') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :int, order: 'BIG'))
      end

      puts "TESTING WRITE INT BIG ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE INT BIG ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_long_be
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffffffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :long, order: 'BIG') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :long, order: 'BIG'))
      end

      puts "TESTING WRITE LONG BIG ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE LONG BIG ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end

  def test_write_long_le
    rand(64).times do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_write_record = []
      rand(0xff).times { stub_write_record << rand(0xffffffff/2) }

      stub_write_record.each { stub_buffer.write(_1, type: :long, order: 'LITTLE') }
      parsed_payload = stub_write_record.length.times.inject([]) do |pl|
        pl.push(stub_buffer.read(type: :long, order: 'LITTLE'))
      end

      puts "TESTING WRITE LONG LITTLE ENDIAN, [PARSED]: #{parsed_payload}"
      puts "TESTING WRITE LONG LITTLE ENDIAN, [WRITE_RECORD]: #{stub_write_record}"
      assert_equal(parsed_payload, stub_write_record)
    end
  end
end
