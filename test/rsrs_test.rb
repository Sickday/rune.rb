# typed: true
require "test_helper"

class RsrsTest < Minitest::Test
  def version_number_test
    refute_nil ::Rsrs::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
