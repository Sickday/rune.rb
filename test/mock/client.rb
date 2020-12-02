require_relative '../../app/rune'

module Client
  class Instance
    using RuneRb::Patches::StringOverrides
    using RuneRb::Patches::IntegerOverrides

    Cipher = Struct.new(:decryptor, :encryptor)

    # Initialize a new client instance
    def initialize(id, params = {})
      @id = rand(id << 32).to_i
      @name = params[:name] || "testbotlet#{id}"
      @pass = 'polimer tape'
      @in = ''
    end

    def login
      open_socket
      write_initial_connection
      read_connection_response
      write_login_block
      read_auth_response
      start_read_loop
    end

    # Decodes a frame using the Peer#cipher.
    # @param frame [RuneRb::Network::Frame] the frame to decode.
    def decode_frame(frame)
      raise 'Invalid cipher for Client!' unless @cipher

      frame.header[:op_code] -= @cipher[:decryptor].next_value & 0xFF
      frame.header[:op_code] = frame.header[:op_code] & 0xFF
      frame.header[:length] = RuneRb::Net::Constants::PACKET_MAP[frame.header[:op_code]]
      puts "Decoding frame: #{frame.inspect}"
      frame
    end

    def start_read_loop
      puts 'Reading Frames...'
      itr = 0
      while true
        itr += 1
        @in << @socket.read_nonblock(32)
        next_frame if @in.size >= 3

        break if @current.header[:op_code] == 109 || itr == 256
      end
    end

    # Parses the next readable frame
    def next_frame
      @current = RuneRb::Net::Frame.new(@in.next_byte)
      @current = decode_frame(@current)
      @current.header[:length] = @in.next_byte if @current.header[:length] == -1
      @current.header[:length].times { @current.push(@in.slice!(0)) }
      handle_frame(@current)
    end

    def handle_frame(frame)
      puts "RECEIVED FRAME:\n"
      puts frame.inspect
    end

    def open_socket
      @socket = TCPSocket.new('0.0.0.0', 43_594)
    rescue StandardError => e
      puts 'An error occurred opening an new socket'
      puts e
      puts e.backtrace
    end

    def read_connection_response
      @in << @socket.read(9)
      puts "Got bytes: #{@in.slice!(0..7).unpack('c*')}" # Useless bytes
      initial_response = @in.slice!(0).unpack('C')
      puts "Got Initial Response #{initial_response}"
      sleep(1)
      @in << @socket.read(8)
      @server_part = @in.slice!(0..7).unpack1('q')
      puts "Received Server Part #{@server_part}"
      @client_part = @id
      puts "Generated Client Part #{@client_part}"
    end

    # Writes the initial connection frame (14, base 37 encoded name)
    def write_initial_connection
      @socket.write_nonblock([14, @name.to_base37].pack('cc'))
    end

    def write_login_block
      login_frame = ''
      login_frame << [255 & 0xff].pack('c') # magic
      login_frame << [317].pack('n') # version
      login_frame << [1].pack('c') # highmem
      9.times do
        login_frame << [0].pack('l') # CRCS
      end

      rsa_frame = ''
      rsa_frame << [@client_part].pack('q')
      rsa_frame << [@server_part].pack('q')
      rsa_frame << [@id].pack('l')
      rsa_frame << "#{@name}\n"
      rsa_frame << "#{@pass}\n"
      rsa_header = [rsa_frame.size & 0xFF, 10 & 0xFF]
      puts "Generated RSA Header: #{rsa_header.to_s}"
      isaac = [@client_part >> 32, @client_part, @server_part >> 32, @server_part]
      @cipher = Cipher.new(RuneRb::Net::ISAAC.new(isaac),
                           RuneRb::Net::ISAAC.new(isaac.map { |seed_idx| seed_idx + 50 }))
      login_header = [16 & 0xFF, (login_frame.bytesize + 40) & 0xFF]
      puts "Generated Login Header: #{login_header.to_s}"
      puts 'Generated Cipher!'
      @socket.write_nonblock(login_header.pack('cc') + login_frame + rsa_header.pack('cc') + rsa_frame)
    end

    def read_auth_response
      @in << @socket.read(1)
      res = @in.slice!(0).unpack('c')
      case res
      when 2
        puts 'GOT AUTHENTICATED RESPONSE!!'
      when 6
        puts 'Got Unexpected Protocol'
      when 11
        puts 'Got Magic Mismatch'
      when 10
        puts 'Got Seed Mismatch'
      when 12
        puts 'Got Unrecognized Con Type'
      else "Got unknown response: #{res}"
      end
    end
  end
end