require 'minitest/autorun'
require 'minitest/pride'

require_relative '../app/rune'

describe Integer do
  before do
    @sample_pool = {
        overflowed_byte: 0xFF + rand(0xFF),
        valid_byte: rand(0xFF),
        overflowed_short: 0xFFFF + rand(0xFF),
        valid_short: rand(0xFFFF),
        overflowed_int: 0xFFFFFFFF + rand(0xFF),
        valid_int: rand(0xFFFFFFFF),
        overflowed_long: 0xFFFFFFFFFFFFFFFF + rand(0xFF),
        valid_long: 0xFFFFFFFFFFFFFFFF
    }.freeze
  end

  describe '#unsigned' do
    context 'when the value of self is greater than'
  end
end
