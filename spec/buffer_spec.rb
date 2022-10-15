require_relative 'spec_helper'

describe RuneRb::IO::Buffer do

  describe '#new' do
    it 'constructs a new {Buffer} object.' do
      stub_buffer = RuneRb::IO::Buffer.new('rw')
      expect(stub_buffer.class).to eql(RuneRb::IO::Buffer)
    end

    it 'injects all functions from {RuneRb::IO::Readable} when the {Buffer#mode} parameter includes "r"' do
      readable_buffers = rand(0xff).times.inject([]) { _1 << RuneRb::IO::Buffer.new('r') }
      readable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::IO::Helpers::Readable)).to eql(true) }
      readable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::IO::Helpers::ReadableNative)).to eql(false) }
      readable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::IO::Helpers::Readable)).to eql(true ) }
    end

    it 'injects all functions from {RuneRb::IO::Writeable} when the {Buffer#mode} parameter includes "w"' do
      writeable_buffers = rand(0xff).times.inject([]) { _1 << RuneRb::IO::Buffer.new('w') }
      writeable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::IO::Helpers::Writeable)).to eql(true ) }
      writeable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::IO::Helpers::Readable)).to eql(false) }
      writeable_buffers.each { |buffer| expect(buffer.singleton_class.included_modules.include?(RuneRb::IO::Helpers::ReadableNative)).to eql(false) }

    end

    it 'raises an error if the {Buffer#mode} parameter does not include "r" or "w"' do
      expect { RuneRb::IO::Buffer.new('sicko') }.to raise_error(StandardError)
    end
  end

  describe '#length' do
    it 'returns an Integer representing the size of the {Buffer#data}' do
      stub_buffers = 32.times.inject([]) { |arr| arr << RuneRb::IO::Buffer.new('rw') }
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
        buff = RuneRb::IO::Buffer.new('rw')
        data = JUNK_DATA_FACTORY.call
        buff << data
        stub_entries[buff] = data
      end
      stub_entries.each { |buffer, data| expect(buffer.peek).to eql(data) }
    end
  end

  describe '#push' do
    it 'appends data directly to the {Buffer#data}' do
      stub_buffer = RuneRb::IO::Buffer.new('rw')
      junk_data = JUNK_DATA_FACTORY.call
      stub_buffer.push(junk_data)
      expect(stub_buffer.peek).to eql(junk_data)
    end
  end
end
