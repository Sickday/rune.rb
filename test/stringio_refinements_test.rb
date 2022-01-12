require_relative 'test_helper'

class StringIORefinementsTest < Minitest::Test
  using RuneRb::Utils::Patches::StringIORefinements

  def setup
    @stubs = []
    rand(0xFF..0xFFF).times do
      stub_io = StringIO.new
      rand(0xFF).times.inject(stub_io) { |io| io << [rand(0xFF)].pack('C') }
      @stubs << stub_io
    end
  end

  def test_reverse
    @stubs.each do |stub_item|
      initial = stub_item.string
      puts "initial: #{initial}"
      stub_item.reverse
      puts "reversed: #{stub_item.string}"
      assert_equal(initial.reverse!, stub_item.string)
    end
    puts "Processed #{@stubs.length} stubs."
  end
end