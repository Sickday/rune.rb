require_relative 'spec_helper'

describe RuneRb::Network::Buffer do

  describe '#new' do
    it 'constructs a new {Buffer} object.' do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      expect(stub_buffer.class).to eql(RuneRb::Network::Buffer)
    end

    it 'injects all functions from {RuneRb::Network::Readable} when the {Buffer#mode} parameter includes "r"' do
      readable_buffers = rand(0xff).times.inject([]) { _1 << RuneRb::Network::Buffer.new('r') }
      readable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::Network::Helpers::Readable)).to eql(true) }
    end

    it 'injects all functions from {RuneRb::Network::Writeable} when the {Buffer#mode} parameter includes "w"' do
      writeable_buffers = rand(0xff).times.inject([]) { _1 << RuneRb::Network::Buffer.new('w') }
      writeable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::Network::Helpers::Writeable)).to eql(true )}
    end

    it 'raises an error if the {Buffer#mode} parameter does not include "r" or "w"' do
      expect { RuneRb::Network::Buffer.new('sicko') }.to raise_error(StandardError)
    end
  end

  describe '#length' do
    it 'returns an Integer representing the size of the {Buffer#data}' do
      stub_buffers = 32.times.inject([]) { |arr| arr << RuneRb::Network::Buffer.new('rw') }
      stub_buffers.each do
        _1 << JUNK_DATA_FACTORY.call
        expect(_1.data.string.bytesize).to eql(_1.length)
      end
    end
  end

  describe '#peek' do
    it 'returns a String representation of the {Buffer#data}' do
      amount = rand(0xFF)
      stub_entries = {}
      amount.times do
        buff = RuneRb::Network::Buffer.new('rw')
        data = JUNK_DATA_FACTORY.call
        buff << data
        stub_entries[buff] = data
      end
      stub_entries.each { |buffer, data| expect(buffer.peek).to eql(data) }
    end
  end

  describe '#rewind' do
    it 'moves the cursor position for the {Buffer#data} to the 0th position' do
      stub_buffers = rand(0xFF..0xFFF).times.inject([]) { |buffer| buffer << RuneRb::Network::Buffer.new('rw') }
      stub_buffers.each do |buffer|
        buffer.data.seek(3)
        expect(buffer.data.pos > 0).to eql(true)
        buffer.rewind
        expect(buffer.data.pos.zero?).to eql(true)
      end
    end
  end

  describe '#position' do
    it 'returns the current cursor position for the {Buffer#data}' do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_buffer.push(JUNK_DATA_FACTORY.call)
      expect(stub_buffer.position.zero?).to eql(false)
      stub_buffer.rewind
      expect(stub_buffer.position.zero?).to eql(true)
    end
  end

  describe '#position=' do
    it 'sets the position of the {Buffer#data} cursor to the passed Integer parameter' do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      stub_buffer.push(JUNK_DATA_FACTORY.call)
      expect(stub_buffer.position > 0).to eql(true)
      stub_offset = rand(stub_buffer.length)
      stub_buffer.position = stub_offset
      expect(stub_buffer.position).to eql(stub_offset)
    end
  end

  describe '#push' do
    it 'appends data directly to the {Buffer#data}' do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      junk_data = JUNK_DATA_FACTORY.call
      stub_buffer.push(junk_data)
      expect(stub_buffer.position.zero?).to eql(false)
      expect(stub_buffer.peek).to eql(junk_data)
    end

    it 'sets the cursor position to 0 if the `rewind_cursor` named parameter is passed' do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      junk_data = JUNK_DATA_FACTORY.call
      stub_buffer.push(junk_data, rewind_cursor: true)
      expect(stub_buffer.position.zero?).to eql(true)
      expect(stub_buffer.peek).to eql(junk_data)
    end
  end
end
