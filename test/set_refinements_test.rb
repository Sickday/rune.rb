require_relative 'test_helper'

# Tests the refinements made to the Set class in `RuneRb::System::Patches::SetRefinements`
class SetRefinementsTest < Minitest::Test

  # Required to apply refinements in the class object's scope.
  using RuneRb::System::Patches::SetRefinements

  # Create initial sample set
  def setup
    @sample_set = (0..rand(0xff)).to_a.to_set
  end

  # SetRefinements#each_consume
  def test_each_consume
    # Capture initial set size
    initial_size = @sample_set.length

    puts "Consumption size: #{initial_size}"

    # Initialize a counter
    consumption_count = 0
    @sample_set.each_consume do |item|
      puts "Consuming #{item}"

      # Increment on each consumption
      consumption_count += 1
    end

    puts "Consumed #{consumption_count} items total."

    # Ensure the size matches up to the amount consumed
    assert_equal(initial_size, consumption_count)

    # Ensure the set is now empty
    assert_equal(@sample_set.length, 0)
  end

  # Test a repopulated consumption
  def test_repopulation_consume
    0.upto(rand(32)) do
      test_each_consume
      @sample_set = (0..rand(0xff)).to_a.to_set
    end

    assert(@sample_set.length, 0)
  end
end