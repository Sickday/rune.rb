module RuneRb::Network::AuthenticationHelper
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  Cipher = Struct.new(:decryptor, :encryptor)

  def authenticate
    @stage ||= :PENDING_CONNECTION
    read_connection if @stage == :PENDING_CONNECTION
    read_block if @stage == :PENDING_BLOCK
    login(validate) if @stage == :PENDING_VALIDATION
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
    @generated_seed = rand(1 << 32) # Druuid.gen

    log "Generated seed: #{@generated_seed & 0xFFFFFFFF}"
    case connection_type
    when RuneRb::Network::CONNECTION_TYPES[:GAME_NEW]
      log! '[Type]: Online'
      write([0].pack('n'))
      disconnect
    when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      log! '[Type]: Update'
      write(Array.new(8, 0)).pack('C' * 8)
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log '[Type]: Login'
      write([0].pack('q')) # Ignored 8 bytes
      write([0].pack('C')) # Response
      write([@generated_seed & 0xFFFFFFFF].pack('q')) # Server key
      @stage = :PENDING_BLOCK
    else
      raise RuneRb::Errors::LoginError.new(:UnrecognizedConnectionType, RuneRb::Network::CONNECTION_TYPES.values, connection_type)
    end
  end

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
                          :Password)

  def read_block
    @connection_block = ConnectionBlock.new(@login.read_byte,               # Type
                                            @login.read_byte - 40,          # Size
                                            @login.read_byte,               # Magic (255)
                                            @login.read_short(false),              # Version
                                            @login.read_byte.positive? ? :LOW : :HIGH, # Low memory?
                                            [].tap { |arr| 9.times { arr << @login.read_int } })
    log 'Read Connection block!', @connection_block.inspect

    @login_block = LoginBlock.new(@login.read_byte,                          # RSA_Block Length
                                  @login.next_byte,                          # RSA_Block OpCode (10)
                                  @login.read_long,                          # Client Part
                                  @login.read_long,                          # Server Part
                                  @login.read_int,                           # UID
                                  @login.read_string,                        # Username
                                  @login.read_string)                        # Password

    log 'Read login block!', @login_block.inspect
    log "Received #{[@login_block[:ServerPart] >> 32, @login_block[:ServerPart]].pack('NN').unpack1('L')}"

    @isaac_seed = [@login_block[:ClientPart] >> 32, @login_block[:ClientPart], # It's important NOT to modify these. Originally was passing Integer#signed(:int). DONT DO THAT.
                   @login_block[:ServerPart] >> 32, @login_block[:ServerPart]]

    @cipher = Cipher.new(RuneRb::Network::ISAAC.new(@isaac_seed),
                         RuneRb::Network::ISAAC.new(@isaac_seed.map { |seed_idx| seed_idx + 50 }))

    log 'Ready for Validation'
    @stage = :PENDING_VALIDATION
    profile = validate
    login(profile)
  end

  def login(profile)
    write([2, profile[:rights], 0].pack('C*')) # Successful Login!
    write_region(region_x: profile.location.x, region_y: profile.location.y)
    write_sidebars
    #write_text('Thanks for testing Rune.rb.')
    #write_text('Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
  end

  def validate
    raise RuneRb::Errors::LoginError.new(:LoginOpcode, [16, 18], @connection_block[:Type]) unless [16, 18].include?(@connection_block[:Type])

    log 'Connection Type Validated!'
    raise RuneRb::Errors::LoginError.new(:ServerHalfMismatch, @generated_seed, @login_block[:ServerPart]) unless @generated_seed == [@login_block[:ServerPart] >> 32, @login_block[:ServerPart]].pack('NN').unpack1('L')

    log 'Session key Validated!'
    raise RuneRb::Errors::LoginError.new(:MagicMismatch, 255, @connection_block[:Magic]) unless @connection_block[:Magic] == 255

    log 'Magic Validated!'
    raise RuneRb::Errors::LoginError.new(:VersionMismatch, [317, 377, ENV['TARGET_PROTOCOL']], @connection_block[:Revision]) unless [317, 377, ENV['TARGET_PROTOCOL']].include?(@connection_block[:Revision])

    log 'Revision Validated!'
    if RuneRb::Database::Profile[@login_block[:UID]]
      profile = RuneRb::Database::Profile[@login_block[:UID]]
      log "Loaded profile for #{profile[:username]}!"
      raise RuneRb::Errors::LoginError.new(:InvalidCredentials, profile[:password], @login_block[:Password]) unless profile[:password] == @login_block[:Password]

    else
      #raise RuneRb::Errors::LoginError.new(:InvalidUsername, nil, @login_block[:Username]) if RuneRb::Database::SYSTEM[:banned_names].include?(@login_block[:Username])

      RuneRb::Database::Profile.register(@login_block, @name_long)
      profile = RuneRb::Database::Profile[@login_block[:UID]]
      log RuneRb::COL.magenta("Registered new profile for #{profile[:username]}")
    end

    @status[:authenticated] = true
    profile
  end
end
