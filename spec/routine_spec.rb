require_relative 'spec_helper'

using RuneRb::System::Patches::IntegerRefinements

describe RuneRb::System::Routine do
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

  describe '#start' do
    context 'when passed a Fiber parameter' do
      it 'will execute all Routine#operations then call Fiber#transfer passing the parameter object' do
        stub = stub_routines.sample

        example_fiber = Fiber.new do
          puts "This is an example Fiber's context"
          true
        end

        expect(stub.start(example_fiber)).to eql(true)
        expect(stub.operations.empty?).to eql(true)
      end
    end

    context 'when passed no parameters' do
      it 'will execute all Routine#operations then yield Routine#successful' do
        stub = stub_routines.sample
        stub.successful = Fiber.new do
          puts 'This is an example Routine#sucessful context'
          true
        end

        expect(stub.start).to eql(true)
        expect(stub.operations.empty?).to eql(true)

        stub2 = stub_routines.sample
        stub2.successful = 99

        expect(stub2.start).to eql(99)
      end
    end
  end

  describe '#add_operation' do
    it 'appends an execution block to the Routine#operations' do
      stub = stub_routines.sample
      initial_operations_length = stub.operations.length
      addition_count = 0
      completed_ops = 0
      rand(32).times do |itr|
        stub.add_operation do
          puts "This is operation #{itr}, checking in."
          completed_ops += 1
        end
        addition_count += 1
      end

      expect(stub.operations.length).to eql(addition_count + initial_operations_length)
      stub.start
      expect(completed_ops).to eql(addition_count)
    end
  end
end