require_relative 'spec_helper'

describe Message do

  context 'when unrecognized mode is passed on initialization' do
    it 'raises an error' do
      expect { Message.new('sicko mode') }.to raise_error(StandardError)
    end
  end

  context 'when mode is readable' do
    let(:readable) do
      256.times.each_with_object([]) do |itr, pool|
        body = rand(itr).to_i.times.inject('') { |buf| buf << [rand(itr).to_i].pack('c*') }
        header = { op_code: itr, size: body.bytesize }
        # Add to the pools
        pool << Message.new('r', header, body)
      end
    end

    it 'includes Readable module' do
      readable.each do |message|
        # Expect module is included in module hierarchy
        expect(message.class.included_modules.include?(Readable)).to eq(true)
      end
    end

    it 'responds true to Message#readable? function' do
      # Test all stubs in the readable pool
      readable.each do |message|
        # Expect message to respond true to Message#readable?
        expect(message.readable?).to eq(true)
      end
    end

    it 'responds nil to Message#mode[:writeable]' do
      readable.each do |message|
        expect(message.mode[:writeable]).to eq(nil)
      end
    end

    it 'does not include Writeable module' do
      readable.each do |message|
        # Ensure no Writable module exists in the Message's module hierarchy
        expect(message.class.included_modules.include?(Writeable)).to eq(false)
      end
    end

    it 'raises a NoMethodError on Writable function calls' do
      readable.each do |message|
        # Expect writable functions to result in NoMethodError
        expect { message.writeable? }.to raise_error(NoMethodError)
      end
    end
  end

  context 'when mode is writable' do
    let(:writeable) do
      256.times.each_with_object([]) do |itr, pool|
        header = { op_code: itr, size: itr }
        # Add to the pools
        pool << Message.new('w', header)
      end
    end

    it 'includes the Writeable module' do
      writeable.each do |message|
        # Ensure module is included in module hierarchy
        expect(message.class.included_modules.include?(Writeable)).to eq(true)
      end
    end

    it 'responds true to Message#writeable?' do
      # Test against all stubs in the writable pool
      writeable.each do |message|
        # Expect message to respond true to Message#writeable?
        expect(message.writeable?).to eq(true)
      end
    end

    it 'responds nil to Message#mode[:readable]' do
      writeable.each do |message|
        expect(message.mode[:readable]).to eq(nil)
      end
    end

    it 'does not include Readable module' do
      writeable.each do |message|
        # Ensure no Readable module exists in the Message's module hierarchy
        expect(message.class.included_modules.include?(Readable)).to eq(false)
      end
    end

    it 'raises a NoMethodError on Readable function calls' do
      writeable.each do |message|
        # Expect readable functions to result in NoMethodError
        expect { message.readable? }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#peek' do

    let(:generic) do
      256.times.each_with_object([]) do |itr, pool|
        body = rand(itr).to_i.times.inject('') { |buf| buf << [rand(itr).to_i].pack('c*') }
        header = { op_code: itr, size: body.bytesize }
        # Add to the pools
        pool << Message.new('rw', header, body)
      end
    end

    it 'returns a duplicate of Message#payload' do
      generic.each do |message|
        expect(message.peek.size == message.header[:length]).to eql(true)
      end
    end
  end
end