module RuneRb::Net::LoginHelper
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  ParsedConnection = Struct.new(:Type, :NameHash, :ConnectionSeed)

  private

  # Reads a connection heading from a frame
  def read_connection
    frame = RuneRb::Net::Frame.new(-1)
    frame.push(@in.slice!(0..1))

    @connection = ParsedConnection.new(frame.read_byte, frame.read_byte, @id & 0xFFFFFFFF)
    log "Generated seed: #{@connection[:ConnectionSeed]}" if RuneRb::DEBUG

    case @connection[:Type]
    when RuneRb::Net::CONNECTION_TYPES[:GAME_NEW]
      log RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Online')}") if RuneRb::DEBUG
      send_data([0].pack('n'))
      disconnect
    when RuneRb::Net::CONNECTION_TYPES[:GAME_UPDATE]
      log RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Update')}") if RuneRb::DEBUG
      send_data(Array.new(8, 0).pack('C' * 8))
    when RuneRb::Net::CONNECTION_TYPES[:GAME_LOGIN]
      log RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Login')}") if RuneRb::DEBUG
      send_data([0].pack('q')) # Ignored 8 bytes
      send_data([0].pack('C')) # Response
      send_data([@connection[:ConnectionSeed]].pack('q')) # Server key
      @status[:auth] = :PENDING_BLOCK
    else # Unrecognized Connection type
    send_data([11].pack('C')) # 11	"Login server rejected session. Please try again."
    disconnect
    end
  end

  # Reads a login block from the provided frame
  def read_block
    frame = RuneRb::Net::Frame.new(-1)
    frame.push(@in.slice!(0..96))

    @login = {}.tap do |hash|
      hash[:Type] = frame.read_byte                             # Type
      hash[:PayloadSize] = frame.read_byte - 40                 # Size
      hash[:Magic] = frame.read_byte                            # Magic (255)
      hash[:Revision] = frame.read_short(false)          # Version
      hash[:LowMem?] = frame.read_byte.positive? ? :LOW : :HIGH # Low memory?
      hash[:CRC] = [].tap { |arr| 9.times { arr << frame.read_int } }
      hash[:RSA_Length] = frame.read_byte                       # RSA_Block Length
      hash[:RSA_OpCode] = frame.read_byte                       # RSA_Block OpCode (10)
      hash[:ClientPart] = frame.read_long                       # Client Part
      hash[:ServerPart] = frame.read_long                       # Server Part
      hash[:UID] = frame.read_int                               # UID
      hash[:Username] = frame.read_string.downcase.capitalize  # Username
      hash[:Password] = frame.read_string                       # Password
      hash[:LoginSeed] = [hash[:ServerPart] >> 32, hash[:ServerPart]].pack('NN').unpack1('L')
      hash[:NameHash] = hash[:Username].to_base37
      hash[:SessionSeed] = [hash[:ClientPart] >> 32,
                            hash[:ClientPart],
                            hash[:ServerPart] >> 32,
                            hash[:ServerPart]]
    end

    @cipher = { decryptor: RuneRb::Net::ISAAC.new(@login[:SessionSeed]),
                encryptor: RuneRb::Net::ISAAC.new(@login[:SessionSeed].map { |seed_idx| seed_idx + 50 }) }
    @endpoint.world.login(self, @login, @connection)
  end
end
