module RuneRb::Network::Helpers::Handshake
  using RuneRb::Utils::Patches::IntegerRefinements

  include RuneRb::Utils::Logging

  def parse_connection_data
    disconnect(:handshake) if @auth[:attempts] >= RuneRb::GLOBAL[:ENV].world_config.login_limit
    @auth[:connection_block].read(@channel[:buffer])
    case @auth[:connection_block].type
    when RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE_COUNT]
      log COLORS.blue("[ConnectionType]: #{COLORS.cyan('Online')} from #{COLORS.cyan.bold(@ip)}")
      send_data([0].pack('C')) # This is used for things that may inquire the current online count of the players. 0 should be replaced with something like @node.world.entities[:players].size
      disconnect(:handshake)
      # Cache parsing is not yet properly handled, and as such we cannot supply a handle for GAME_UPDATE type connections.
      # when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      # log RuneRb::GLOBAL[:COLOR].blue("[ConnectionType]:\t#{RuneRb::GLOBAL[:COLOR].cyan('Update')} from #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)}") if RuneRb::GLOBAL[:DEBUG]
      # send_data(Array.new(8, 0).pack('C' * 8))
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log COLORS.blue("[ConnectionType]: #{COLORS.cyan('Login')} from #{COLORS.cyan.bold(@ip)}")
      send_data([0, RuneRb::Network::LOGIN_RESPONSES[:OK], @auth[:seed]].pack('QCQ'))
      @auth[:stage] = :parse_login
    else # Unrecognized Connection type
      err COLORS.magenta("Unrecognized ConnectionType: #{@auth[:connection_block].type}")
      send_data([RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION]].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect(:handshake)
    end
  rescue StandardError => e
    err '[AuthenticationStack]: An error occurred while reading credential_block data!', e.message
    err e.backtrace&.join("\n")
  end

  def parse_login_data
    @auth[:login_block].read(@channel[:buffer])
    @auth[:stage] = :parse_cipher
  rescue StandardError => e
    err 'An error occurred while reading login data in handshake.', e.message
    err e.backtrace&.join("\n")
  ensure
    process if @channel[:buffer].remaining >= 16
  end

  def parse_cipher_data
    @cipher = CipherBlock.new
    @cipher.read(@channel[:buffer])
    @cipher.generate
    @auth[:stage] = :parse_credentials
  rescue StandardError => e
    err 'An error occurred while reading cipher data in handshake.', e.message
    err e.backtrace&.join("\n")
  ensure
    process if @channel[:buffer].remaining >= 6
  end

  # Read credential data from the buffer.
  def parse_credential_data
    @auth[:attempts].nil? ? @auth[:attempts] = 1 : @auth[:attempts] += 1
    @auth[:credentials_block].read(@channel[:buffer], @cipher.server_chunk)
    @auth[:stage] = :authenticate
  end

  private

  ConnectionBlock = Struct.new(:type, :name_hash) do

    def read(payload)
      return unless payload.remaining >= 2

      self.type = payload.read_byte
      self.name_hash = payload.read_byte
    end
  end

  CipherBlock = Struct.new(:incoming, :outgoing, :client_chunk, :server_chunk) do

    def generate
      seed = self.client_chunk + self.server_chunk
      self.incoming = RuneRb::Network::ISAAC.new(seed)
      self.outgoing = RuneRb::Network::ISAAC.new(seed.map { |idx| idx + 50 })
    end

    def read(payload)
      self.client_chunk = [payload.read_int, payload.read_int]
      self.server_chunk = [payload.read_int, payload.read_int]
    end
  end

  CredentialsBlock = Struct.new(:username, :password, :uid, :name_hash, :signature, :seed, :client_seed) do
    using RuneRb::Utils::Patches::StringRefinements

    def read(payload, server_chunk)
      return unless payload.remaining >= 6

      self.client_seed = server_chunk.pack('NN').unpack1('q')
      self.uid = payload.read_int
      self.username = payload.read(type: :string).downcase
      self.password = payload.read(type: :string).downcase
      self.name_hash = username.to_base37
    end
  end

  LoginBlock = Struct.new(:op_code, :payload_size, :magic, :revision, :low_memory, :crc, :rsa_length, :rsa_opcode) do

    def read(payload)
      return unless payload.remaining >= 44

      self.op_code = payload.read_byte
      self.payload_size = payload.read_byte - 40
      self.magic = payload.read_byte
      self.revision = payload.read_short
      self.low_memory = payload.read_byte.positive? ? :LOW : :HIGH
      self.crc = [].tap { |arr| 9.times { arr << payload.read_int } }
      self.rsa_length = payload.read_byte if RuneRb::GLOBAL[:ENV].server_config.protocol == 317
      self.rsa_opcode = payload.read_byte
    end
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