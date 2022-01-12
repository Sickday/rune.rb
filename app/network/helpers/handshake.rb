module RuneRb::Network::Helpers::Handshake
  using RuneRb::Utils::Patches::StringRefinements
  using RuneRb::Utils::Patches::IntegerRefinements

  # @!attribute [r] cipher
  # @return [Struct] a struct containing Ciphers for Incoming and Outgoing data.
  attr :cipher

  AuthenticationStack = Struct.new(:connection_block, :credential_block, :attempts, :stage)

  def read_connection
    return unless @channel[:buffer].length >= 2

    @authentication.connection_block[:type] = @channel[:buffer].read_byte
    @authentication.connection_block[:name_hash] = @channel[:buffer].read_byte

    case @authentication.connection_block[:type]
    when RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE_COUNT]
      log COLORS.blue("[ConnectionType]:\t#{COLORS.cyan('Online')} from #{COLORS.cyan.bold(@ip)}")
      send_data([0].pack('C')) # This is used for things that may inquire the current online count of the players. 0 should be replaced with something like @node.world.entities[:players].size
      disconnect(:handshake)
      # Cache parsing is not yet properly handled, and as such we cannot supply a handle for GAME_UPDATE type connections.
      # when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      # log RuneRb::GLOBAL[:COLOR].blue("[ConnectionType]:\t#{RuneRb::GLOBAL[:COLOR].cyan('Update')} from #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)}") if RuneRb::GLOBAL[:DEBUG]
      # send_data(Array.new(8, 0).pack('C' * 8))
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log COLORS.blue("[ConnectionType]:\t#{COLORS.cyan('Login')} from #{COLORS.cyan.bold(@ip)}")
      send_data([0, RuneRb::Network::LOGIN_RESPONSES[:OK], seed].pack('QCQ'))
      @authentication.stage = :read_credential
    else # Unrecognized Connection type
      err COLORS.magenta("Unrecognized ConnectionType: #{@authentication.connection_block.type}")
      send_data([RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION]].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect(:handshake)
    end
  rescue StandardError => e
    err '[AuthenticationStack]: An error occurred while reading connection_block data!', e.message
    err e.backtrace&.join("\n")
    disconnect(:handshake)
  end

  def read_credentials
    attempts.nil? ? attempts = 1 : attempts += 1

    @authentication.credential_block[:operation_code] = @channel[:buffer].read_byte                                # Op Code
    @authentication.credential_block[:payload_size] = @channel[:buffer].read_byte - 40                             # Size
    @authentication.credential_block[:magic] = @channel[:buffer].read_byte                                         # Magic (255)
    @authentication.credential_block[:revision] = @channel[:buffer].read_short                                     # Version
    @authentication.credential_block[:low_mem] = @channel[:buffer].read_byte.positive? ? :LOW : :HIGH              # Memory Mode
    @authentication.credential_block[:crc] = [].tap { |arr| 9.times { arr << @channel[:buffer].read_int } }        # CRC
    @authentication.credential_block[:rsa_len] = @channel[:buffer].read_byte if RuneRb::GLOBAL[:REVISION] == 317   # RSA_Block Length - This is a hacky solution that is entirely caused by my choice in clients. It may not be entirely necessary on all clients.
    @authentication.credential_block[:rsa_opcode] = @channel[:buffer].read_byte                                    # RSA_Block OpCode (10)
    @authentication.credential_block[:client_pcs] = [@channel[:buffer].read_int, @channel[:buffer].read_int]                  # Client Parts
    @authentication.credential_block[:server_pcs] = [@channel[:buffer].read_int, @channel[:buffer].read_int]                  # Server Parts
    @authentication.credential_block[:uid] = @channel[:buffer].read_int                                            # UID
    @authentication.credential_block[:credentials] = {}.tap do |creds|                                  # Credentials
      creds[:Username] = @channel[:buffer].read(type: :string).downcase
      creds[:Password] = @channel[:buffer].read(type: :string).downcase
      creds[:NameHash] = creds[:Username].to_base37
      creds[:Signature] = @authentication.signature.to_s
    end.freeze

    @authentication.credential_block[:login_seed] = @authentication.credential_block[:server_pcs].pack('NN').unpack1('q')
    @authentication.credential_block[:session_seed] = @authentication.credential_block[:client_pcs] + @authentication.credential_block[:server_pcs]

    @cipher[:incoming] = RuneRb::Network::ISAAC.new(@authentication.credential_block[:session_seed])
    @cipher[:outgoing] = RuneRb::Network::ISAAC.new(@authentication.credential_block[:session_seed].map { |seed_idx| seed_idx + 50 })

    @authentication.stage = :authenticate
  rescue StandardError => e
    err '[AuthenticationStack]: An error occurred while reading credential_block data!', e.message
    err e.backtrace&.join("\n")
    if attempts >= RuneRb::Network::GLOBAL[:NETWORK].configuration.login_limit
      disconnect(:handshake)
    else
      retry
    end
  end

  private

  def init_auth
    @authentication = AuthenticationStack.new
    @authentication.attempts = 0
    @authentication.connection_block = {}
    @authentication.credential_block = {}
    @authentication.signature = Druuid.gen
    @authentication.seed = (@authentication.signature & (0xFFFFFFFF / 2))
    @authentication.stage = :read_connection
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