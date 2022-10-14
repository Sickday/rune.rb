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
        expect(_1.data.bytesize).to eql(_1.length)
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

  describe '#push' do
    it 'appends data directly to the {Buffer#data}' do
      stub_buffer = RuneRb::Network::Buffer.new('rw')
      junk_data = JUNK_DATA_FACTORY.call
      stub_buffer.push(junk_data)
      expect(stub_buffer.peek).to eql(junk_data)
    end
  end
end
