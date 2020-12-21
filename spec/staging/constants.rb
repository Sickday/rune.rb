module Constants
  # Acceptable byte orders in which multi-byte values can be read.
  BYTE_ORDERS = %i[BIG MIDDLE INVERSE_MIDDLE LITTLE].freeze
  BYTE_SIZE = 8
  RW_TYPES = {
    bit: %i[bit BIT],
    byte: %i[byte b Byte BYTE B],
    short: %i[short s SHORT S],
    medium: %i[tribyte, tri-byte, medium, med, m, tb, int24, MED, MEDIUM, M, TRIBYTE, TRI-BYTE, INT24],
    int: %i[int integer i INT INTEGER I],
    long: %i[long l LONG g],
    smart: %i[smart, SMART],
    string: %i[str, string, STRING, STR]
  }.freeze
  BYTE_MUTATIONS = {
    std: %i[STD, STANDARD, s, NONE],
    add: %i[A Add a add ADD],
    sub: %i[S Sub Subtract s sub subtract SUB SUBTRACT],
    neg: %i[C c N n Negate Neg neg negate NEG NEGATE]
  }.freeze
  # Bit masks for bit packing
  BIT_MASK_OUT = (0...32).collect { |i| (1 << i) - 1 }
end