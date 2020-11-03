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

  ConnectionBlock = Struct.new(:Type,
                               :PayloadSize,
                               :Magic,
                               :Revision,
                               :LowMem?,
                               :CRC)

  LoginBlock = Struct.new(:RSA_Length,
                          :RSA_OpCode,
                          :ClientPart,
                          :ServerPart,
                          :UID,
                          :Username,
                          :Password,
                          :Seed)
  def authenticate
    @login = RuneRb::Network::InFrame.new(-1)
    @login.push(@socket.read_nonblock(98))
    @stage ||= :PENDING_CONNECTION

    case @stage
    when :PENDING_CONNECTION then read_connection
    when :PENDING_BLOCK then read_block
    when :PENDING_VALIDATION then login(validate)
    end
  rescue RuneRb::Errors::LoginError => e
    case e.type
    when :UnrecognizedConnectionType, :MagicMismatch
      write([11].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect
    when :SeverHalfMismatch
      write([10].pack('C')) # 10	"Unable to connect. Bad session-id."
      disconnect
    when :LoginOpcode
      write([20].pack('C')) # 20	"Invalid loginserver requested. Please try using a different world."
      disconnect
    when :InvalidCredentials
      write([3].pack('C')) # 3	"Invalid username or password."
      disconnect
    when :VersionMismatch
      write([6].pack('C')) # 6	"RuneScape has been updated! Please reload this page."
      disconnect
    end
  end

  private

  def read_connection
    connection_type = @login.read_byte
    @name_long = @login.read_byte
    @seed = @id & 0xFFFFFFFF

    log "Generated seed: #{@generated_seed & 0xFFFFFFFF}"
    case connection_type
    when RuneRb::Network::CONNECTION_TYPES[:GAME_NEW]
      log! '[Type]: Online'
      send_data([0].pack('n'))
      disconnect
    when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      log! '[Type]: Update'
      send_data(Array.new(8, 0)).pack('C' * 8)
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log '[Type]: Login'
      send_data([0].pack('q')) # Ignored 8 bytes
      send_data([0].pack('C')) # Response
      send_data([@seed].pack('q')) # Server key
      @stage = :PENDING_BLOCK
    else
      raise RuneRb::Errors::LoginError.new(:UnrecognizedConnectionType, RuneRb::Network::CONNECTION_TYPES.values, connection_type)
    end
  end

  def read_block
    @connection_block = ConnectionBlock.new(@login.read_byte,               # Type
                                            @login.read_byte - 40,          # Size
                                            @login.read_byte,               # Magic (255)
                                            @login.read_short(false), # Version
                                            @login.read_byte.positive? ? :LOW : :HIGH, # Low memory?
                                            [].tap { |arr| 9.times { arr << @login.read_int } })
    log 'Read Connection half!'

    @login_block = LoginBlock.new(@login.read_byte,                          # RSA_Block Length
                                  @login.read_byte,                          # RSA_Block OpCode (10)
                                  @login.read_long,                          # Client Part
                                  @login.read_long,                          # Server Part
                                  @login.read_int,                           # UID
                                  @login.read_string,                        # Username
                                  @login.read_string)                        # Password
    @login_block[:Seed] = [@login_block[:ServerPart] >> 32, @login_block[:ServerPart]].pack('NN').unpack1('L')
    log 'Read Credential half!'

    @isaac_seed = [@login_block[:ClientPart] >> 32, @login_block[:ClientPart], # It's important NOT to modify these. Originally was passing Integer#signed(:int). DONT DO THAT.
                   @login_block[:ServerPart] >> 32, @login_block[:ServerPart]]

    @cipher = Cipher.new(RuneRb::Network::ISAAC.new(@isaac_seed),
                         RuneRb::Network::ISAAC.new(@isaac_seed.map { |seed_idx| seed_idx + 50 }))

    log 'Ready for Validation'
    @stage = :PENDING_VALIDATION
    login(validate)
  end

  def login(profile)
    send_data([2, profile[:rights], 0].pack('CCC')) # Successful Login!
    @context_update = true
    #write_region(region_x: @region_tile[:x], region_y: @region_tile[:y])
    #write_mock_update
    #write_sidebars
    #write_text('Thanks for testing Rune.rb.')
    #write_text('Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
  end

  def validate
    if [16, 18].include?(@connection_block[:Type])
      log 'Connection Type Validated!'
    else
      err 'Unrecognized Connection type!', "Received: #{@connection_block[:Type]}"
    end

    if @seed == @login_block[:Seed]
      log 'Connection Type Validated!'
    else
      err 'Seed Mismatch!:', "Expected: #{@seed}, Received: #{[@login_block[:ServerPart] >> 32, @login_block[:ServerPart]].pack('NN').unpack1('L')}"
    end

    if @connection_block[:Magic] == 255
      log 'Magic Validated!'
    else
      err 'Unexpected Magic!', "Expected: 255, Received: #{@connection_block[:Magic]}"
    end

    if [317, 377, ENV['TARGET_PROTOCOL']].include?(@connection_block[:Revision])
      log 'Revision Validated!'
    else
      err 'Unexpected Protocol', "Expected: #{[317, 377, ENV['TARGET_PROTOCOL']]}, Received: #{@connection_block[:Revision]}"
    end

    if RuneRb::Database::Profile[@login_block[:UID]]
      profile = RuneRb::Database::Profile[@login_block[:UID]]
      log RuneRb::COL.blue("Loaded profile for #{RuneRb::COL.cyan(profile[:username])}!")
      raise RuneRb::Errors::LoginError.new(:InvalidCredentials, profile[:password], @login_block[:Password]) unless profile[:password] == @login_block[:Password]

    else
      #raise RuneRb::Errors::LoginError.new(:InvalidUsername, nil, @login_block[:Username]) if RuneRb::Database::SYSTEM[:banned_names].include?(@login_block[:Username])

      RuneRb::Database::Profile.register(@login_block, @name_long)
      profile = RuneRb::Database::Profile[@login_block[:UID]]
      log RuneRb::COL.blue("Registered new profile for #{RuneRb::COL.cyan(profile[:username])}")
    end

    @status[:authenticated] = true
    profile
  end
end
