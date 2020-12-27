module RuneRb::Network::LoginHelper
  using RuneRb::System::Patches::IntegerRefinements
  using RuneRb::System::Patches::StringRefinements

  # @return [Hash] a structured map of login block data.
  attr :login

  private

  # Reads a connection heading from a frame
  def read_connection(task: Async::Task.current)
    task.async do
      frame = RuneRb::Network::Frame.new(-1)
      frame.read(@socket, 2)

      @login ||= {}
      @login[:header] = { Type: frame.read_byte, NameHash: frame.read_byte, ConnectionSeed: @id & 0xFFFFFFFF }
      log "Generated seed: #{@login[:header][:ConnectionSeed]}" if RuneRb::GLOBAL[:RRB_DEBUG]

      case @login[:header][:Type]
      when RuneRb::Network::CONNECTION_TYPES[:GAME_NEW]
        log RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Online')}") if RuneRb::GLOBAL[:RRB_DEBUG]
        send_data([0].pack('n'))
        disconnect
      when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
        log RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Update')}") if RuneRb::GLOBAL[:RRB_DEBUG]
        send_data(Array.new(8, 0).pack('C' * 8))
      when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
        log RuneRb::COL.blue("[ConnectionType]:\t#{RuneRb::COL.cyan('Login')}") if RuneRb::GLOBAL[:RRB_DEBUG]
        send_data([0].pack('q')) # Ignored 8 bytes
        send_data([0].pack('C')) # Response
        send_data([@login[:header][:ConnectionSeed]].pack('q')) # Server key
        @status[:auth] = :PENDING_BLOCK
      else # Unrecognized Connection type
      err RuneRb::COL.magenta("Unrecognized ConnectionType: #{@login[:header][:Type]}")
      send_data([11].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect
      end
    end
  end

  # Reads a login block from the provided frame
  def read_block(task: Async::Task.current)
    task.async do
      frame = RuneRb::Network::Frame.new(-1)
      frame.read(@socket, 97)

      @login[:block] = {}.tap do |hash|
        hash[:Type] = frame.read_byte                             # Type
        hash[:PayloadSize] = frame.read_byte - 40                 # Size
        hash[:Magic] = frame.read_byte                            # Magic (255)
        hash[:Revision] = frame.read_short                        # Version
        hash[:LowMem?] = frame.read_byte.positive? ? :LOW : :HIGH # Low memory?
        hash[:CRC] = [].tap { |arr| 9.times { arr << frame.read_int } }
        #hash[:RSA_Length] = frame.read_byte                       # RSA_Block Length
        hash[:RSA_OpCode] = frame.read_byte                       # RSA_Block OpCode (10)
        hash[:ClientPart] = frame.read_long                       # Client Part
        hash[:ServerPart] = frame.read_long                       # Server Part
        hash[:UID] = frame.read_int                               # UID
        hash[:Username] = frame.read_string.downcase              # Username
        hash[:Password] = frame.read_string                       # Password
        hash[:LoginSeed] = [hash[:ServerPart] >> 32, hash[:ServerPart]].pack('NN').unpack1('L')
        hash[:SessionSeed] = [hash[:ClientPart] >> 32, hash[:ClientPart], hash[:ServerPart] >> 32, hash[:ServerPart]]
        hash[:NameHash] = hash[:Username].to_base37
      end

      @cipher = { decryptor: RuneRb::Network::ISAAC.new(@login[:block][:SessionSeed]),
                  encryptor: RuneRb::Network::ISAAC.new(@login[:block][:SessionSeed].map { |seed_idx| seed_idx + 50 }) }
      @status[:auth] = :PENDING_WORLD
    end
  end
end
