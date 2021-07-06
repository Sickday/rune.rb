module RuneRb::Network::Handshake
  using RuneRb::Base::Patches::IntegerRefinements
  using RuneRb::Base::Patches::StringRefinements

  # @return [Hash] a structured map of login block data.
  attr :login

  private

  # Reads a connection heading from a message
  def read_connection

    # Read a couple of unsigned bytes representing the type and hash
    @login = {}.tap do |hash|
      hash[:Type] = @socket.read_nonblock(1).unpack1('c').unsigned(:byte)
      hash[:NameHash] = @socket.read_nonblock(1).unpack1('c').unsigned(:byte)
      # generate our seed from the <@id>
      hash[:ConnectionSeed] = @id.unsigned(:int)
    end
    log! "Read connection: #{@login.inspect}"

    case @login[:Type]
    when RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE_COUNT]
      log RuneRb::GLOBAL[:COLOR].blue("[ConnectionType]:\t#{RuneRb::GLOBAL[:COLOR].cyan('Online')} from #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)}") if RuneRb::GLOBAL[:DEBUG]
      send_data([0].pack('C'))  # This is used for things that may inquire the current online count of the players. 0 should be replaced with something like @node.world.entities[:players].size
      disconnect(:handshake)
      # Cache parsing is not yet properly handled, and as such we cannot supply a handle for GAME_UPDATE type connections.
      # when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      # log RuneRb::GLOBAL[:COLOR].blue("[ConnectionType]:\t#{RuneRb::GLOBAL[:COLOR].cyan('Update')} from #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)}") if RuneRb::GLOBAL[:DEBUG]
      # send_data(Array.new(8, 0).pack('C' * 8))
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log RuneRb::GLOBAL[:COLOR].blue("[ConnectionType]:\t#{RuneRb::GLOBAL[:COLOR].cyan('Login')} from #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)}") if RuneRb::GLOBAL[:DEBUG]
      send_data([0, RuneRb::Network::LOGIN_RESPONSES[:OK], @login[:ConnectionSeed]].pack('qCq'))
      @status[:auth] = :PENDING_BLOCK
    else # Unrecognized Connection type
      err RuneRb::GLOBAL[:COLOR].magenta("Unrecognized ConnectionType: #{@login[:Type]}")
      send_data([RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION]].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect(:handshake)
    end
  end

  # Reads a login block from the provided message
  def read_block
    block = RuneRb::Base::Types::Message.new('r', { op_code: -1 }, :FIXED)
    @socket.read_nonblock(96, block.payload)
    @login.tap do |hash|
      hash[:OperationCode] = block.read                # Op Code
      hash[:PayloadSize] =   block.read(:byte, mutation: :STD) - 40             # Size
      hash[:Magic] =         block.read(:byte, mutation: :STD)                  # Magic (255)
      hash[:Revision] =      block.read(:short, mutation: :STD)     # Version
      hash[:LowMem?] =       block.read(:byte, mutation: :STD).positive? ? :LOW : :HIGH # Memory Mode
      hash[:CRC] = [].tap { |arr| 9.times { arr << block.read(:int, mutation: :STD) } } # CRC
      hash[:RSA_Length] =     block.read(:byte, mutation: :STD)                   # RSA_Block Length
      hash[:RSA_OpCode] =     block.read(:byte, mutation: :STD)                   # RSA_Block OpCode (10)
      hash[:ClientPart] =     [block.read(:int, mutation: :STD), block.read(:int, mutation: :STD)]      # Client Part
      hash[:ServerPart] =     [block.read(:int, mutation: :STD), block.read(:int, mutation: :STD)]     # Server Part
      hash[:UID] =            block.read(:int, mutation: :STD)      # UID
      hash[:Credentials] = {}.tap do |creds|
        creds[:Username] = block.read(:string).downcase
        creds[:Password] = block.read(:string)
        creds[:NameHash] = creds[:Username].to_base37
      end.freeze # Credentials
      hash[:LoginSeed] =      hash[:ServerPart].pack('NN').unpack1('q')
      hash[:SessionSeed] =    (hash[:ClientPart] + hash[:ServerPart]).collect { |value| value.signed(:integer) }
    end

    log! "Read login: #{@login.inspect}"
    @cipher = { incoming: RuneRb::Network::ISAAC.new(@login[:SessionSeed]),
                outgoing: RuneRb::Network::ISAAC.new(@login[:SessionSeed].map { |seed_idx| seed_idx + 50 }) }

    @status[:auth] = :PENDING_WORLD
  end
end


# Copyright (c) 2021, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.