module RuneRb::IO::Helpers::ReadableNative
  # Read a byte value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the byte value.
  def read_byte(mutation: :STD, signed: false)
    val = mutate(@data.slice!(0).unpack1(signed ? 'c' : 'C'), mutation)
    @position += 1
    val
  end

  # Reads a short value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the short value
  # @param order [String] they byte order to read the short value
  def read_short(signed: false, mutation: :STD, order: 'BIG')
    val = 0
    case order
    when 'BIG'
      val += mutate(@data.slice!(0..1).unpack1(signed ? 's>' : 'S>'), mutation)
    when 'LITTLE'
      val += mutate(@data.slice!(0..1).unpack1(signed ? 's<' : 'S<'), mutation)
    else read_short(signed: signed, mutation: mutation, order: 'BIG')
    end
    val
  end

  # Reads a medium value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the medium value
  # @param order [String] they byte order to read the medium value
  def read_medium(signed: false, mutation: :STD, order: 'BIG')
    val = 0
    case order
    when 'BIG'
      val += read_byte(signed: signed) << 16
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed, mutation: mutation)
    when 'MIDDLE'
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 16
    when 'LITTLE'
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed) << 16
    else read_medium(signed: signed, mutation: mutation, order: 'BIG')
    end
    val
  end

  # Reads a integer value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the integer value
  # @param order [String] they byte order to read the integer value
  def read_int(signed: false, mutation: :STD, order: 'BIG')
    val = 0
    case order
    when 'BIG'
      val += mutate(@data.slice!(0..3).unpack1(signed ? 'i>' : 'I>'), mutation)
    when 'MIDDLE'
      val += read_byte(signed: signed) << 8
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 24
      val += read_byte(signed: signed) << 16
      return val
    when 'INVERSE_MIDDLE'
      val += read_byte(signed: signed) << 16
      val += read_byte(signed: signed) << 24
      val += read_byte(signed: signed, mutation: mutation)
      val += read_byte(signed: signed) << 8
      return val
    when 'LITTLE'
      val += mutate(@data.slice!(0..3).unpack1(signed ? 'i<' : 'I<'), mutation)
    else read_int(signed: signed, mutation: mutation, order: 'BIG')
    end
    val
  end

  # Reads a long value from the {Buffer#data}
  # @param signed [Boolean] should the value be signed.
  # @param mutation [String] mutation that should be applied to the long value
  # @param order [String] they byte order to read the long value
  def read_long(signed: false, mutation: :STD, order: 'BIG')
    case order
    when 'BIG'
      mutate(@data.slice!(0..7).unpack1(signed ? 'q>' : 'Q>'), mutation)
    when 'LITTLE'
      mutate(@data.slice!(0..7).unpack1(signed ? 'q<' : 'Q<'), mutation)
    else read_long(signed: signed, mutation: mutation, order: 'BIG')
    end
  end

end
