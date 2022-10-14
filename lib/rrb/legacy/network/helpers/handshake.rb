module RuneRb::Network::Helpers::Handshake
  include RuneRb::Utils::Logging

  CredentialData = Struct.new(:uid, :username, :password) do
    using RuneRb::Patches::StringRefinements

    def name_hash
      username.to_base37
    end
  end

  SeedData = Struct.new(:client_chunk, :server_chunk) do
    using RuneRb::Patches::StringRefinements

    def read_seed(buffer)
      self.client_chunk = [((buffer.data.next_byte & 0xFF) << 24) + ((buffer.data.next_byte & 0xFF)<< 16) + ((buffer.data.next_byte & 0xFF) << 8) + (buffer.data.next_byte & 0xFF),
                           ((buffer.data.next_byte & 0xFF) << 24) + ((buffer.data.next_byte & 0xFF)<< 16) + ((buffer.data.next_byte & 0xFF) << 8) + (buffer.data.next_byte & 0xFF)]
      self.server_chunk = [((buffer.data.next_byte & 0xFF) << 24) + ((buffer.data.next_byte & 0xFF)<< 16) + ((buffer.data.next_byte & 0xFF) << 8) + (buffer.data.next_byte & 0xFF),
                           ((buffer.data.next_byte & 0xFF) << 24) + ((buffer.data.next_byte & 0xFF)<< 16) + ((buffer.data.next_byte & 0xFF) << 8) + (buffer.data.next_byte & 0xFF)]
      self
    end

    def raw_seed
      server_chunk.pack('NN').unpack1('q')
    end

    def seed_array
      client_chunk + server_chunk
    end
  end

  private

  def read_connection
    @handshake = { connection_type: @buffer.read(type: :byte), name_hash: @buffer.read(type: :byte) }

    case @handshake[:connection_type]
    when RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE_COUNT]
      log COLORS.blue("[ConnectionType]: #{COLORS.cyan('Online')}")
      send_data([0].pack('C')) # This is used for things that may inquire the current online count of the players. 0 should be replaced with something like @node.world.entities[:players].size
      disconnect(:handshake)
      # Cache parsing is not yet properly handled, and as such we cannot supply a handle for GAME_UPDATE type connections.
      # when RuneRb::Network::CONNECTION_TYPES[:GAME_UPDATE]
      # log RuneRb::GLOBAL[:COLOR].blue("[ConnectionType]:\t#{RuneRb::GLOBAL[:COLOR].cyan('Update')} from #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)}") if RuneRb::GLOBAL[:DEBUG]
      # send_data(Array.new(8, 0).pack('C' * 8))
    when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN]
      log COLORS.blue("[ConnectionType]: #{COLORS.cyan('Login')}")
      send_data([0, RuneRb::Network::LOGIN_RESPONSES[:OK], @cipher[:seed]].pack('QCQ'))
      @stage = :handshake
    else # Unrecognized Connection type
      err COLORS.magenta("Unrecognized ConnectionType: #{@type}")
      send_data([RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION]].pack('C')) # 11	"Login server rejected session. Please try again."
      disconnect(:handshake)
    end
  end

  def read_handshake
    @handshake[:op_code] = @buffer.read(type: :byte, signed: false)
    @handshake[:payload_size] = @buffer.read(type: :byte, signed: false) - 40
    @handshake[:magic] = @buffer.read(type: :byte, signed: false)
    @handshake[:protocol] = @buffer.read(type: :short, signed: false)
    @handshake[:low_memory] = @buffer.read(type: :byte, signed: false).positive? ? true : false
    @handshake[:crc] = 9.times.inject([]) { |arr| arr << @buffer.read(type: :int, signed: false) }
    @handshake[:rsa_length] = @buffer.read(type: :byte, signed: false)
    @handshake[:rsa_opcode] = @buffer.read(type: :byte, signed: false)
    @handshake[:seed] = SeedData.new.read_seed(@buffer)
    @handshake[:credentials] = CredentialData.new(@buffer.read(type: :int), @buffer.read(type: :string).downcase, @buffer.read(type: :string).downcase)
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