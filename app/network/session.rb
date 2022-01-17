module RuneRb::Network
  # A Session object encapsulates a connected TCPSocket object and provides functions for interacting with it.
  class Session < EventMachine::Connection
    using RuneRb::Utils::Patches::IntegerRefinements
    using RuneRb::Utils::Patches::StringRefinements

    include RuneRb::Utils::Logging
    include Helpers::Handshake
    include Helpers::Dispatcher
    include Helpers::Parser

    # @!attribute [r] sig
    # @return [Integer] the Session signature.
    attr :sig

    # @!attribute [r]
    # @return [String, IPAddr, Addrinfo] the IPV4 address that corresponds to the underlying <@socket> object.
    attr :ip

    # @!attribute [r]
    # @return [Auth] a map of authentication data for the session.
    attr :auth

    # @!attribute [r]
    # @return [Struct] a struct containing cipher data.
    attr :cipher

    # @!attribute [r]
    # @return [Hash] a map of Time database for the session.
    attr :duration

    # @!attribute [r]
    # @return [Boolean, NilClass] is the session closed
    attr :closed

    def post_init
      _, @ip = Socket.unpack_sockaddr_in(get_peername)
      @sig = Druuid.gen
      @duration = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), start: Time.now }
      @channel = { buffer: RuneRb::Network::Buffer.new('rw'), position: 0 }
      @auth = { attempts: 0, seed: (@sig & (0xFFFFFFFF / 2)),
                credentials_block: CredentialsBlock.new,
                connection_block: ConnectionBlock.new,
                login_block: LoginBlock.new, stage: :parse_connection }
      log! COLORS.green.bold("New Session created @ #{@ip}")
    end

    # Pushes data read from the socket to the buffer.
    # @param data [String] the received data.
    def receive_data(data)
      @channel[:buffer].push(data)
    rescue StandardError => e
      err 'An error occurred while receiving data!', e.message
      err e.backtrace&.join("\n")
    ensure
      process
    end

    # Registers a Context to the Session.
    # @param ctx [RuneRb::Game::Entity::Context] the Context to register
    def register_context(ctx)
      @context = ctx
    end

    # The current up-time for the session.
    def up_time(formatted: true)
      up = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @duration[:time]).round(3).to_i
      formatted ? up.to_ftime : up
    end

    def inspect
      COLORS.blue("[IP:] #{COLORS.cyan.bold(@ip)} || [ID:] #{COLORS.cyan.bold(@sig)} || [UP:] #{COLORS.cyan.bold(up_time)} || [LOGIN_STAGE:] #{COLORS.cyan.bold(@auth[:stage])}")
    end

    # Ends the session closing it's socket and updating the <@authentication.stage> to :LOGGED_OUT.
    # @param reason [Symbol] the reason for the disconnect. Exclusively used for logging purposes.
    def disconnect(reason = :manual)
      case reason
      when :logout then log! COLORS.green.bold('Session ended by client.')
      when :authentication then err 'Session disconnected during authentication.'
      when :io_error then err 'Session disconnected due to IO error.'
      when :handshake then err 'Session disconnected during handshake.'
      when :manual then err 'Session forcefully closed by Server. This is typically caused by a closed socket.'
      when :peer then err 'Session forcefully closed by peer. This could be ECONNABORTED or ECONNRESET.'
      else err "Session disconnected for reason: #{reason}"
      end
    ensure
      @auth[:stage] = :logged_out
      @closed = true
      close_connection_after_writing
      log! inspect
    end

    private

    # Processes data from the buffer.
    def process
      case @auth[:stage]
      when :parse_connection then parse_connection_data
      when :parse_login then parse_login_data
      when :parse_cipher then parse_cipher_data
      when :parse_credentials then parse_credential_data
      when :logged_in then parse(next_message(@channel[:buffer], @cipher.incoming))
      end
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