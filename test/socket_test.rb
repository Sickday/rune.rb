require_relative '../app/rune'
require 'nio'
require 'socket'
require 'faker'

NAMES = %w[Pat Guy zukyak some_gai jeff kaiser].freeze

UID = rand(1 << 16).freeze
##
# just make sum sokets bro
class Client
  using RuneRb::Patches::StringOverrides
  using RuneRb::Patches::IntegerOverrides

  def initialize(socket)
    @socket = socket
    @name = NAMES.sample
    simulate_login
    puts 'Client initialized'
    read_pulse
    puts "PAYLOAD:\n"
    puts @in.unpack('c*')
  end

  def simulate_login
    puts 'Simulating login'
    name_hash = @name.to_base37
    connection_payload = [14, name_hash].pack('cc')
    @socket.write_nonblock(connection_payload)
    ignorables = @socket.read(8) # 8 ignored bytes
    puts 'Received ignorables'
    response = @socket.read(1)
    puts "Received Respose #{response.unpack('c')}"
    server_seed = @socket.read(8).unpack1('q')
    puts "Read seed #{server_seed}"
    puts 'Ready to send block'

    frame = RuneRb::Network::MetaFrame.new(16, false, false)
    frame.write_byte(255) # magic
    frame.write_short(317.unsigned(:short))
    frame.write_byte(1) # highmem
    9.times { frame.write_int(0) } # crc

    rsa = RuneRb::Network::MetaFrame.new(10)

    base = rand(1 << 31)
    client_half = [].tap do |arr|
      arr << (base << 32)
      arr << base
    end

    server_half = [].tap do |arr|
      arr << (server_seed << 32)
      arr << server_seed
    end
    rsa.write_long(client_half.pack('NN').unpack1('L'))
    rsa.write_long(server_half.pack('NN').unpack1('L'))
    rsa.write_int(UID)
    rsa.write_string(@name)
    rsa.write_string(@name.chars.shuffle.join)
    #size = rsa.size
    rsa_payload = rsa.compile
    frame.write_bytes(rsa_payload.prepend([rsa_payload.size].pack('c')))

    puts "Generated frame"
    @socket.write_nonblock(frame.compile)
  end

  def read_pulse
    @in = @socket.read(256)
  end
end

clients = []

3.times do
  clients << Client.new(TCPSocket.open('localhost', 43594))
end