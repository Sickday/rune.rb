require_relative 'spec_helper'

using RuneRb::System::Patches::IntegerRefinements

##
# A Chain object is represents a collection of linked Routines that will execute sequentially.
# When Chain#link(routine) is called, a Chain object is returned that will control the execution of the linked routine collection.
describe RuneRb::System::Chain do
  let(:stub_routines) do
    rand(0xfff).times.each_with_object([]) do |itr, arr|
      arr << RuneRb::System::Routine.new do
        puts "Executing routine #{itr}"
        sample = Faker::FunnyName.two_word_name
        puts "OG: #{sample}"
        puts "BINARY: #{sample.bytes.map(&:brep).join}"
      end
    end
  end

  let(:stub_chain) { RuneRb::System::Chain.new }

  describe '#<<' do
    it 'appends a Routine object to the Routine#links collection' do
      stub_routine = stub_routines.sample
      # Capture the initial size.
      initial_length = stub_chain.length
      # Add a link to the Chain
      stub_chain << stub_routine
      # Check the new length
      post_fill_length = stub_chain.length
      expect(initial_length + 1).to eql(post_fill_length)
      expect(stub_chain.links.values.include?(stub_routine)).to eql(true)
    end
  end

  describe '#execute' do
    it 'executes all Routine objects within the Routine#links collection' do
      # Add some links to the Chain
      rand(stub_routines.length).times { stub_chain << stub_routines.sample }
      # Execute the Chain
      stub_chain.execute
      # This should be 0 as we want to make sure the routines are consumed as they're executed. Default behavior is to consume links as they are executed.
      expect(stub_chain.links.length.zero?).to eql(true)
    end
  end
end
