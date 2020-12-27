require_relative 'spec_helper'

describe Channel do
  let(:stub_channels) do
    @in, @out = IO.pipe
    { in: Channel.new(@in), out: Channel.new(@out) }
  end

  let(:stub_messages) do
    64.times.inject([]) do |arr, itr|
      content = rand(0xff).times.inject('') { |buf| buf << [rand(0xff)].pack('c') }
      header = { op_code: itr, size: content.bytesize }
      arr << Message.new('rw', header, content)
      arr
    end
  end

  context 'when initialized with a non-IO object' do
    it 'raises a TypeError' do
      Shoe = Struct.new(:inspect)
      expect { Channel.new(Shoe.new('literally just a shoe')) }.to raise_error(TypeError)
    end
  end

  context 'when initialized with a closed IO object' do
    it 'raises a IOError' do
      inn,out = IO.pipe
      out.close
      inn.close
      expect { Channel.new(out) }.to raise_error(IOError)
      expect { Channel.new(inn) }.to raise_error(IOError)
    end
  end

  context 'when initialized with a closed Socket object' do
    it 'raises a SocketError' do
      stub_socket = Socket.new(:INET, :STREAM)
      stub_socket.close
      expect { Channel.new(stub_socket) }.to raise_error(SocketError)
    end
  end

  context 'when closed' do
    it 'raises an error on calls to Channel#submit' do
      stub_channels[:in].close
      # An error is raised when we try to submit a message to a closed Channel
      expect{ stub_channels[:in].submit(stub_messages.shift) }.to raise_error(StandardError)
    end
  end

  describe '#close' do
    it 'closes the Channel' do
      stub_channels[:in].close
      expect(stub_channels[:in].closed?).to eq(true)
    end
  end
end