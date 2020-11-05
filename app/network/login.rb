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

  ParsedFrame = Struct.new(:Type, :PayloadSize, :Magic, :Revision,
                          :LowMem?, :CRC, :RSA_Length, :RSA_OpCode,
                          :ClientPart, :ServerPart, :UID, :Username,
                          :Password, :NameHash, :Seed)
  def authenticate
    @login = RuneRb::Network::InFrame.new(-1)
    @login.push(@socket.read_nonblock(98))
    @stage ||= :PENDING_CONNECTION

    case @stage
    when :PENDING_CONNECTION then read_connection
    when :PENDING_BLOCK then read_block
    end
  rescue RuneRb::Errors::LoginError => e
    case e.type
    when :UnrecognizedConnectionType, :MagicMismatch
      send_data([11].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect
    when :SeverHalfMismatch
      send_data([10].pack('C')) # 10	"Unable to connect. Bad session-id."
      disconnect
    when :LoginOpcode
      send_data([20].pack('C')) # 20	"Invalid loginserver requested. Please try using a different world."
      disconnect
    when :InvalidCredentials
      send_data([3].pack('C')) # 3	"Invalid username or password."
      disconnect
    when :VersionMismatch
      send_data([6].pack('C')) # 6	"RuneScape has been updated! Please reload this page."
      disconnect
    end
  end

  private

  def read_connection
    connection_type = @login.read_byte
    @name_long = @login.read_byte
    @seed = @id & 0xFFFFFFFF

    log "Generated seed: #{@seed}" if RuneRb::DEBUG
    case connection_type
    when RuneRb::Network::CONNECTION_TYPES[:GAME_NEW]
      log! RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Online')}") if RuneRb::DEBUG
      send_data([0].pack('n'))
      write_disconnect
    when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      log! RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Update')}") if RuneRb::DEBUG
      send_data(Array.new(8, 0)).pack('C' * 8)
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log! RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Login')}") if RuneRb::DEBUG
      send_data([0].pack('q')) # Ignored 8 bytes
      send_data([0].pack('C')) # Response
      send_data([@seed].pack('q')) # Server key
      @stage = :PENDING_BLOCK
    else
      raise RuneRb::Errors::LoginError.new(:UnrecognizedConnectionType, RuneRb::Network::CONNECTION_TYPES.values, connection_type)
    end
  end

  def read_block
    @block = ParsedFrame.new(@login.read_byte,               # Type
                             @login.read_byte - 40,          # Size
                             @login.read_byte,               # Magic (255)
                             @login.read_short(false), # Version
                             @login.read_byte.positive? ? :LOW : :HIGH, # Low memory?
                             [].tap { |arr| 9.times { arr << @login.read_int } },
                             @login.read_byte,                          # RSA_Block Length
                             @login.read_byte,                          # RSA_Block OpCode (10)
                             @login.read_long,                          # Client Part
                             @login.read_long,                          # Server Part
                             @login.read_int,                           # UID
                             @login.read_string,                        # Username
                             @login.read_string,                        # Password
                             @name_long)

    @block[:Seed] = [@block[:ServerPart] >> 32,
                     @block[:ServerPart]].pack('NN').unpack1('L')

    log RuneRb::COL.green("Parsed Login Block: #{RuneRb::COL.cyan(@block.inspect)}") if RuneRb::DEBUG


    isaac = [@block[:ClientPart] >> 32, @block[:ClientPart], @block[:ServerPart] >> 32, @block[:ServerPart]]
    @cipher = Cipher.new(RuneRb::Network::ISAAC.new(isaac),
                         RuneRb::Network::ISAAC.new(isaac.map { |seed_idx| seed_idx + 50 }))
    @profile = validate
    login
  end

  def login
    send_data([2, @profile[:rights], 0].pack('CCC')) # Successful Login!
    write_sidebars
    # write_text('Thanks for testing Rune.rb.')
    #write_text('Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
  end

  def validate
    if [16, 18].include?(@block[:Type])
      log 'Connection Type Validated!' if RuneRb::DEBUG
    else
      err 'Unrecognized Connection type!', "Received: #{@block[:Type]}"
    end

    if @seed == @block[:Seed]
      log 'Seed Validated!' if RuneRb::DEBUG
    else
      err 'Seed Mismatch!:', "Expected: #{@seed}, Received: #{[@block[:ServerPart] >> 32, @block[:ServerPart]].pack('NN').unpack1('L')}"
    end

    if @block[:Magic] == 255
      log 'Magic Validated!' if RuneRb::DEBUG
    else
      err 'Unexpected Magic!', "Expected: 255, Received: #{@block[:Magic]}"
    end

    if [317, 377, ENV['TARGET_PROTOCOL']].include?(@block[:Revision])
      log 'Revision Validated!' if RuneRb::DEBUG
    else
      err 'Unexpected Protocol', "Expected: #{[317, 377, ENV['TARGET_PROTOCOL']]}, Received: #{@block[:Revision]}"
    end

    if RuneRb::Database::Profile[@block[:Username]]
      profile = RuneRb::Database::Profile[@block[:Username]]
      log RuneRb::COL.blue("Loaded profile for #{RuneRb::COL.cyan(profile[:name])}!")
      raise RuneRb::Errors::LoginError.new(:InvalidCredentials, profile[:password], @block[:Password]) unless profile[:password] == @block[:Password]

    else
      #raise RuneRb::Errors::LoginError.new(:InvalidUsername, nil, @login_block[:Username]) if RuneRb::Database::SYSTEM[:banned_names].include?(@login_block[:Username])

      RuneRb::Database::Profile.register(@block)
      profile = RuneRb::Database::Profile[@block[:Username]]
      log RuneRb::COL.blue("Registered new profile for #{RuneRb::COL.cyan(profile[:name].capitalize)}")
    end

    @status[:authenticated] = true
    profile
  end
end
