##
# Login Responses:
# 1 = Please Wait 2 Seconds
# 2 = OK
# 4 = Banned
# * Thanks wL
module RuneRb::Network::AuthenticationHelper
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  Cipher = Struct.new(:decryptor, :encryptor)

  ParsedConnection = Struct.new(:Type, :NameHash, :ConnectionSeed)

  ParsedLogin = Struct.new(:Type, :PayloadSize, :Magic, :Revision,
                           :LowMem?, :CRC, :RSA_Length, :RSA_OpCode,
                           :ClientPart, :ServerPart, :UID, :Username,
                           :Password, :LoginSeed)

  def authenticate
    if @status[:authenticated] == :PENDING_BLOCK
      @login_frame = RuneRb::Network::InFrame.new(-1)
      @login_frame.push(@socket.read_nonblock(96))
      read_block
    else
      @connection_frame = RuneRb::Network::InFrame.new(-1)
      @connection_frame.push(@socket.read_nonblock(2))
      read_connection
    end
  end

  private

  def read_connection
    @connection = ParsedConnection.new(@connection_frame.read_byte,
                                       @connection_frame.read_byte,
                                       @id & 0xFFFFFFFF)
    log "Generated seed: #{@connection[:ConnectionSeed]}" if RuneRb::DEBUG

    case @connection[:Type]
    when RuneRb::Network::CONNECTION_TYPES[:GAME_NEW]
      log! RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Online')}") if RuneRb::DEBUG
      send_data([0].pack('n'))
      write_disconnect
    when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      log! RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Update')}") if RuneRb::DEBUG
      send_data(Array.new(8, 0).pack('C' * 8))
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log! RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Login')}") if RuneRb::DEBUG
      send_data([0].pack('q')) # Ignored 8 bytes
      send_data([0].pack('C')) # Response
      send_data([@connection[:ConnectionSeed]].pack('q')) # Server key
      @status[:authenticated] = :PENDING_BLOCK
    else # Unrecognized Connection type
      send_data([11].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect
    end
  end

  def read_block
    @login = ParsedLogin.new(@login_frame.read_byte, # Type
                             @login_frame.read_byte - 40, # Size
                             @login_frame.read_byte, # Magic (255)
                             @login_frame.read_short(false), # Version
                             @login_frame.read_byte.positive? ? :LOW : :HIGH, # Low memory?
                             [].tap { |arr| 9.times { arr << @login_frame.read_int } },
                             @login_frame.read_byte, # RSA_Block Length
                             @login_frame.read_byte, # RSA_Block OpCode (10)
                             @login_frame.read_long, # Client Part
                             @login_frame.read_long, # Server Part
                             @login_frame.read_int, # UID
                             @login_frame.read_string, # Username
                             @login_frame.read_string) # Password

    @login[:LoginSeed] = [@login[:ServerPart] >> 32, @login[:ServerPart]].pack('NN').unpack1('L')

    log RuneRb::COL.green("Parsed Login Block: #{RuneRb::COL.cyan(@block.inspect)}") if RuneRb::DEBUG


    isaac = [@login[:ClientPart] >> 32, @login[:ClientPart], @login[:ServerPart] >> 32, @login[:ServerPart]]
    @cipher = Cipher.new(RuneRb::Network::ISAAC.new(isaac),
                         RuneRb::Network::ISAAC.new(isaac.map { |seed_idx| seed_idx + 50 }))
    validate
  end

  def validate
    if [16, 18].include?(@login[:Type])
      log 'Connection Type Validated!' if RuneRb::DEBUG
    else
      err 'Unrecognized Connection type!', "Received: #{@login[:Type]}"
      send_data([11].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect
    end

    if @login[:LoginSeed] == @connection[:ConnectionSeed]
      log 'Seed Validated!' if RuneRb::DEBUG
    else
      err 'Seed Mismatch!:', "Expected: #{@connection[:ConnectionSeed]}, Received: #{@login[:LoginSeed]}"
      send_data([10].pack('C')) # 10	"Unable to connect. Bad session-id."
      disconnect
    end

    if @login[:Magic] == 255
      log 'Magic Validated!' if RuneRb::DEBUG
    else
      err 'Unexpected Magic!', "Expected: 255, Received: #{@login[:Magic]}"
      send_data([11].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect
    end

    if [317, 377, ENV['TARGET_PROTOCOL']].include?(@login[:Revision])
      log 'Revision Validated!' if RuneRb::DEBUG
    else
      err 'Unexpected Protocol', "Expected: #{[317, 377, ENV['TARGET_PROTOCOL']]}, Received: #{@login[:Revision]}"
      send_data([6].pack('C')) # 6	"RuneScape has been updated! Please reload this page."
      disconnect
    end

    if RuneRb::Database::Profile[@login[:Username]]
      profile = RuneRb::Database::Profile[@login[:Username]]
      log RuneRb::COL.blue("Loaded profile for #{RuneRb::COL.cyan(profile[:name])}!")
    else
      RuneRb::Database::Profile.register(@login, @connection[:NameHash])
      profile = RuneRb::Database::Profile[@login[:Username]]
      log RuneRb::COL.blue("Registered new profile for #{RuneRb::COL.cyan(profile[:name].capitalize)}")
    end

    if profile[:password] == @login[:Password]
      log RuneRb::COL.green("Credentials valid for #{RuneRb::COL.cyan(profile[:name])}!")
    else
      log RuneRb::COL.red("Invalid Credentials for #{RuneRb::COL.cyan(profile[:name])}!")
      send_data([3].pack('C')) # 3	"Invalid username or password."
      disconnect
    end

    # TODO: Validate username.
    @profile = profile
    @status[:authenticated] = :PENDING_LOGIN
  end
end
