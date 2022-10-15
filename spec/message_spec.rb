require_relative 'spec_helper'

describe RuneRb::IO::Message do
  describe '#new' do
    it 'constructs a new {RuneRb::IO::Buffer} with the passed body parameter' do
      junk_data = JUNK_DATA_FACTORY.call
      stub_message = RuneRb::IO::Message.new(body: junk_data)
      expect(stub_message.body.class).to eql(RuneRb::IO::Buffer)
      expect(stub_message.body.peek).to eql(junk_data)
    end

    it 'constructs a new {Message#header} struct with the passed op_code, length, and type' do
      rand(0xff).times do |itr|
        junk_data = JUNK_DATA_FACTORY.call
        stub_message = RuneRb::IO::Message.new(op_code: itr, body: junk_data)
        expect(stub_message.header.op_code).to eql(itr)
        expect(stub_message.header.length).to eql(junk_data.bytesize)
        expect(stub_message.header.type).to eql(:FIXED)
      end
    end
    it 'raises a {StandardError} if a body parameter is passed whose type is not {RuneRb::IO::Buffer}, {StringIO}, or {String}' do
      expect { RuneRb::IO::Message.new(body: :SickoMode) }.to raise_error(StandardError)
    end
  end

  describe '#compile' do
    it 'returns a {String} with binary data to represent the message' do
      junk_data = JUNK_DATA_FACTORY.call
      op_code = rand(0xFF)
      stub_message = RuneRb::IO::Message.new(op_code: op_code, body: junk_data)
      bin = stub_message.compile
      expect(bin.class).to eql(String)
      expect(bin.include?(junk_data)).to eql(true)
      expect(bin.include?([stub_message.header.op_code].pack('C'))).to eql(true)
    end
    it 'includes the length of the {Message#body} in the header if the {Message#type} is either :VARIABLE_BYTE, or :VARIABLE_SHORT' do
      junk_data = JUNK_DATA_FACTORY.call
      stub_message = RuneRb::IO::Message.new(body: junk_data,
                                                  type: junk_data.bytesize >= 0xFF ? :VARIABLE_SHORT : :VARIABLE_BYTE)
      out = stub_message.compile
      expect(out.include?([junk_data.bytesize].pack(junk_data.bytesize >= 0xFF ? 'c' : 'n'))).to eql(true)
    end

    it 'excludes the {Message#header#op_code} and {Message#header#length) if the {Message#type} is :RAW' do
      junk_data = JUNK_DATA_FACTORY.call
      stub_message = RuneRb::IO::Message.new(body: junk_data, type: :RAW)
      out = stub_message.header.compile_header
      msg_out = stub_message.compile
      expect(out.empty?).to eql(true)
      expect(out.include?([stub_message.header.op_code].pack('C'))).to eql(false)
      expect(out.include?([stub_message.header.length].pack(junk_data.bytesize >= 0xFF ? 'c' : 'n'))).to eql(false)
      expect(msg_out).to eql(junk_data)
    end

    it 'excludes the {Message#header#length if the {Message#type} is :FIXED' do
      junk_data = JUNK_DATA_FACTORY.call
      stub_message = RuneRb::IO::Message.new(body: junk_data, type: :FIXED)
      out = stub_message.header.compile_header
      msg_out = stub_message.compile
      expect(out.empty?).to eql(false)
      expect(out.include?([stub_message.header.op_code].pack('C'))).to eql(true)
      expect(out.include?([stub_message.header.length].pack(junk_data.bytesize >= 0xFF ? 'c' : 'n'))).to eql(false)
      expect(msg_out.include?([stub_message.header.op_code].pack('C'))).to eql(true)
    end
  end
end
