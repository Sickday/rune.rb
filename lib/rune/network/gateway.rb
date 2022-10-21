module RuneRb::Network
  class Gateway < RuneRb::Component
    using RuneRb::Patches::StringRefinements
    using RuneRb::Patches::SetRefinements
    using RuneRb::Patches::IntegerRefinements

    include RuneRb::Utils::Logging
    include RuneRb::Network::Helpers::Authentication

    # @!attribute [r] connections
    # @return [Hash] a map of addresses to connection pools and details.
    attr :connections

    # Receives a socket and attempts to validate the connection
    # @param socket [TCPSocket] the socket to receive
    def receive(socket)
      ip = socket.remote_address.ip_address
      if @connections.key?(ip)
        throttle, code = needs_throttle?(ip)
        if throttle == false
          @connections[ip][:pool] << socket
          @connections[ip][:last_connection] = Time.now
          validate_connection(socket)
        else
          reject(code, socket)
          socket.write_nonblock([RuneRb::Network::LOGIN_RESPONSES[code]].pack('C'))
          socket.close
        end
      else
        @connections[ip] = { pool: Set.new([socket]), last_connection: Time.now }
        validate_connection(socket)
      end
    end

    def process
      @connections.each_value do |connection|
        connection[:pool].each do |socket|
          validate_handshake(socket)
        end
      end
    ensure
      reap
    end

    def register(target)
      @target = target
    end

    # Closes and removes socket connections that are closed
    def reap
      @connections.each_value do |connection|
        connection[:pool].each_consume do |socket|
          connection[:pool].delete(socket) if socket.closed?
        end
      end
    end

    # Has the Gateway reached a closed state?
    # @return [Boolean]
    def closed?
      @closed
    end

    def shutdown
      return if @closed

      conn_count = @connections.each_value.inject(0) do |count, connection|
        connection[:pool].each(&:close)
        count += connection[:pool].length
        count
      end
      log "Closed #{conn_count} connections."
    ensure
      @closed = true
    end

    def setup
      @connections = {}
      log! 'Gateway initialized!'
    ensure
      @closed = false
    end

    private

    def needs_throttle?(ip)
      return true, :TOO_MANY_ATTEMPTS if (@connections[ip][:last_connection] - Time.now) < ENV['RRB_NET_LOGIN_INTERVAL'].to_f
      return true, :TOO_MANY_CONNECTIONS if (@connections[ip][:pool].length + 1) > ENV['RRB_NET_LOGIN_LIMIT'].to_i

      [false, :OK]
    end

    def validate_connection(socket)
      connection_block = {}.tap do |block|
        block[:buffer] = RuneRb::IO::Buffer.new('r', data: socket.read_nonblock(2))
        block[:type] = block[:buffer].read
        block[:hash] = block[:buffer].read
      end

      if valid_connection?(connection_block[:type])
        permit(socket, connection_block[:type])
      else
        reject(:REJECTED_SESSION, socket)
      end
    rescue IO::WaitReadable
      err 'Socket does not have enough data for connection validation!'
      reject(:REJECTED_SESSION, socket)
    end

    def validate_handshake(socket)
      handshake_block = {}.tap do |block|
        block[:buffer] = RuneRb::IO::Buffer.new('r', data: socket.read_nonblock(5192))
        block[:op_code] = block[:buffer].read(type: :byte)
        block[:payload_size] = block[:buffer].read(type: :byte) - 40
        block[:magic] = block[:buffer].read(type: :byte)
        block[:protocol] = block[:buffer].read(type: :short)
        block[:low_memory] = block[:buffer].read(type: :byte).positive? ? :LOW : :HIGH
        block[:crc] = [].tap { |arr| 9.times { arr << block[:buffer].read(type: :int) } }
        block[:rsa_length] = block[:buffer].read(type: :byte) if RuneRb::Network::PROTOCOL == 317
        block[:rsa_opcode] = block[:buffer].read(type: :byte)
        block[:cipher_client_chunk] = [block[:buffer].read(type: :int), block[:buffer].read(type: :int)]
        block[:cipher_server_chunk] = [block[:buffer].read(type: :int), block[:buffer].read(type: :int)]
        block[:client_seed] = block[:cipher_server_chunk].pack('NN').unpack1('q')
        block[:uid] = block[:buffer].read(type: :int)
        block[:username] = block[:buffer].read(type: :string).downcase
        block[:password] = block[:buffer].read(type: :string).downcase
        block[:name_hash] = block[:username].to_base37
      end

      if valid_handshake?(handshake_block)
        @target.register(socket)
        @connections[socket.remote_address.ip_address][:pool].delete(socket)
      else
        reject(:REJECTED_SESSION, socket)
      end
    rescue IO::WaitReadable
      err 'Socket does not have enough data for handshake validation!'
    end

    def reject(code, socket)
      socket.write_nonblock([RuneRb::Network::LOGIN_RESPONSES[code]].pack('C'))
      @connections[socket.remote_address.ip_address][:pool].delete(socket)
    end

    # Permits a socket's authentication attempt
    # @param socket [TCPSocket] the socket to permit
    # @param type [Integer] the connection type.
    def permit(socket, type)
      case type
      when RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE] then log 'GAME_ONLINE connection type has not yet been implemented!'
      when RuneRb::Network::CONNECTION_TYPES[:GAME_LOGIN], RuneRb::Network::CONNECTION_TYPES[:GAME_RECONNECT]
        socket.write_nonblock([0, RuneRb::Network::LOGIN_RESPONSES[:OK], @target.signature[:seed]].pack('QCQ'))
        log RuneRb::LOGGER.colors.blue("[ConnectionType]: #{RuneRb::LOGGER.colors.cyan('Login')} from #{RuneRb::LOGGER.colors.cyan.bold(socket.inspect)}")
      else
        err "Unable to permit connection type: #{type}!"
        reject(:REJECTED_SESSION, socket)
      end
    end
  end
end

# Copyright (c) 2022, Patrick W.
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
