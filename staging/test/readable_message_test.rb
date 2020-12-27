require 'test_helper'

class ReadableTest < Minitest::Test
  def setup
    # Create a generic stub pool of messages
    @generic_pool = rand(RuneRb::Network::FRAME_SIZES.length).times.inject([]) do |pool, itr|
      content = if RuneRb::Network::FRAME_SIZES[itr].negative?
                  rand(0xffff).times.inject('') { |buf| buf << [rand(0xff)].pack('C') }
                else
                  RuneRb::Network::FRAME_SIZES[itr].times.inject('') { |buf| buf << [rand(0xff)].pack('c') }
                end

      header = { op_code: itr & 0xFF, size: content&.bytesize }
      pool << Message.new('w', header, content)
    end

    # Create a readable stub pool of messages
    @readable_pool = 256.times.inject([]) { |pool| pool << Message.new('r'); pool }
  end

  def test_read_from
    stub = StringIO.new

    # Write some messages to our outgoing stub
    bytes_written = 0
    8.times do
      message = @generic_pool.sample
      bytes_written += stub.syswrite(message.compile(:VARIABLE_BYTE).force_encoding(Encoding::BINARY))
      puts "Wrote messages:\n#{message.inspect}"
    end
    puts "Wrote #{bytes_written} bytes"

    stub.rewind

    bytes_read = 0
    8.times do
      # Read a message
      readable = @readable_pool.shift
      readable.read(:io, source: stub)
      bytes_read += 1 # OpCode
      bytes_read += 1 unless readable.header[:length].zero? || readable.header[:length].negative? # length
      bytes_read += readable.header[:length]
      puts "Read message:\n#{readable.inspect}"
    end
    puts "Read #{bytes_read} bytes"

    assert_equal(bytes_written, bytes_read)
  end
end
