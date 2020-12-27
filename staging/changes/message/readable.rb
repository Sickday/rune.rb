module Readable
  using RuneRb::System::Patches::StringRefinements
  include Constants

  # @return [NIO::ByteBuffer, String] the readable content.
  attr :readable

  # Read data from the payload according to the option parameter.
  # @param type [Symbol] the type of data to read
  # @param opt [Hash] options that are to be observed when reading the data.
  def read(type = :byte, opt = { signed: false, mutation: :STD, order: :BIG,})
    return unless Message.validate(self, :read, opt)

    case type
    when *RW_TYPES[:byte] then read_byte(opt[:signed], opt[:mutation])
    when *RW_TYPES[:short] then read_short(opt[:signed], opt[:mutation], opt[:order])
    when *RW_TYPES[:medium] then read_medium(opt[:signed], opt[:mutation], opt[:order])
    when *RW_TYPES[:int] then read_int(opt[:signed], opt[:mutation], opt[:order])
    when *RW_TYPES[:long] then read_long(opt[:signed], opt[:mutation], opt[:order])
    when *RW_TYPES[:string] then read_string
    when :bytes then read_bytes(opt[:amount], opt[:mutation])
    when :reverse_bytes, :negative_bytes then read_bytes_reverse(opt[:amount], opt[:mutation])
    when :io, :socket then read_from_io(opt[:io] || opt[:source])
    when :header then read_header(opt[:source])
    end
  end

  # Ensure the message is considered readable
  def readable?
    true
  end

  private

  # Read a byte value from the payload
  # @param signed [Boolean] should the value be signed.
  # @param mut [Symbol] mutation that should be applied to the byte value.
  def read_byte(signed, mut)
    val = 0
    case @readable
    when String
      val |= mutate(@readable.next_byte, mut)
    when NIO::ByteBuffer
      val |= mutate(@readable.get(1).unpack1('c'), mut)
    end
    signed ? val : val & 0xff
  end

  # Reads a short value from the payload
  # @param signed [Boolean] should the value be signed.
  # @param mut [Symbol] mutation that should be applied to the short value
  # @param order [Symbol] they byte order to read the short value
  def read_short(signed, mut, order)
    val = 0
    case order
    when :BIG
      val |= read(signed: signed) << 8
      val |= read(signed: signed, mutation: mut)
    when :LITTLE
      val |= read(signed: signed, mutation: mut)
      val |= read(signed: signed) << 8
    end
    val
  end

  # Reads a medium value from the payload
  # @param signed [Boolean] should the value be signed.
  # @param mut [Symbol] mutation that should be applied to the medium value
  # @param order [Symbol] they byte order to read the medium value
  def read_medium(signed, mut, order)
    val = 0
    case order
    when :BIG
      val |= read(signed: signed, mutations: mut) << 16
      val |= read(signed: signed, mutations: mut) << 8
      val |= read(signed: signed, mutations: mut)
    when :MIDDLE
      val |= read(signed: signed, mutations: mut) << 8
      val |= read(signed: signed, mutations: mut)
      val |= read(signed: signed, mutations: mut)<< 16
    when :LITTLE
      val |= read(signed: signed, mutations: mut)
      val |= read(signed: signed, mutations: mut) << 8
      val |= read(signed: signed, mutations: mut) << 16
    end
    val
  end

  # Reads a integer value from the payload
  # @param signed [Boolean] should the value be signed.
  # @param mut [Symbol] mutation that should be applied to the integer value
  # @param order [Symbol] they byte order to read the integer value
  def read_int(signed, mut, order)
    val = 0
    case order
    when :BIG
      val |= read(signed: signed, mutation: mut) << 24
      val |= read(signed: signed, mutation: mut) << 16
      val |= read(signed: signed, mutation: mut) << 8
      val |= read(signed: signed, mutation: mut)
    when :MIDDLE
      val |= read(signed: signed, mutation: mut) << 8
      val |= read(signed: signed, mutation: mut)
      val |= read(signed: signed, mutation: mut) << 24
      val |= read(signed: signed, mutation: mut) << 16
    when :INVERSE_MIDDLE
      val |= read(signed: signed, mutation: mut) << 16
      val |= read(signed: signed, mutation: mut) << 24
      val |= read(signed: signed, mutation: mut)
      val |= read(signed: signed, mutation: mut) << 8
    when :LITTLE
      val |= read(signed: signed, mutation: mut)
      val |= read(signed: signed, mutation: mut) << 8
      val |= read(signed: signed, mutation: mut) << 16
      val |= read(signed: signed, mutation: mut) << 24
    end
    val
  end

  # Reads a long value from the payload
  # @param signed [Boolean] should the value be signed.
  # @param mut [Symbol] mutation that should be applied to the long value
  # @param order [Symbol] they byte order to read the long value
  def read_long(signed, mut, order)
    val = 0
    case order
    when :BIG
      val |= read(signed: signed, mutation: mut) << 56
      val |= read(signed: signed, mutation: mut) << 48
      val |= read(signed: signed, mutation: mut) << 40
      val |= read(signed: signed, mutation: mut) << 32
      val |= read(signed: signed, mutation: mut) << 24
      val |= read(signed: signed, mutation: mut) << 16
      val |= read(signed: signed, mutation: mut) << 8
      val |= read(signed: signed, mutation: mut)
    when :LITTLE
      val |= read(signed: signed, mutation: mut)
      val |= read(signed: signed, mutation: mut) << 8
      val |= read(signed: signed, mutation: mut) << 16
      val |= read(signed: signed, mutation: mut) << 24
      val |= read(signed: signed, mutation: mut) << 32
      val |= read(signed: signed, mutation: mut) << 40
      val |= read(signed: signed, mutation: mut) << 48
      val |= read(signed: signed, mutation: mut) << 56
    end
    val
  end

  # Reads a string from the payload
  # @return [String] the resulting string.
  def read_string
    val = ''
    while (res = read)
      break if res == 10

      val << res
    end
    val
  end

  # Read multiple bytes from the payload
  # @param amount [Integer] the amount of bytes to read
  # @param mut [Symbol] the mutation to apply to read bytes.
  def read_bytes(amount, mut)
    amount.times.each_with_object([]) { |_idx, arr| arr << read(mutation: mut) }
  end

  # Probably did this wrong
  def read_bytes_reverse(amount, mut)
    case @readable
    when NIO::ByteBuffer
      @readable.flip
      amount.times.inject([]) { |arr| arr << mutate(@readable.get(1).unpack1('C'), mut); arr }
    when String
      amount.times.inject([]) { |arr| arr << mutate(@readable.reverse.next_byte, mut); arr }
    end
  end

  # Reads a header from a IO source object.
  # @param source [IO, StringIO, Socket] the object to read from. must respond to #read_nonblock
  # @return [Struct] the frozen header that was read.
  def read_header(source)
    op_code = source.read_nonblock(1).next_byte & 0xff


    length = if RuneRb::Network::FRAME_SIZES[op_code].negative?  # Variable Short length
               source.read_nonblock(2).next_short & 0xffff
             else
               RuneRb::Network::FRAME_SIZES[op_code]
             end

    header = Message::Header.new(op_code, length)
    header.freeze
  end

  # Reads data from a socket into the message's payload
  # @param io [IO, StringIO, Socket] the io to read from
  def read_from_io(io)
    @header = read(:header, source: io)
    puts "Reading content for #{@header.inspect}"
    unless @header[:length].negative? || @header[:length].zero?
      @readable = @header[:length].times.inject('') { |buf| buf << io.read_nonblock(1) }
    end
  end
end