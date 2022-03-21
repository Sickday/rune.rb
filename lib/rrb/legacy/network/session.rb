module RuneRb::Network
  # A Session object encapsulates a connected TCPSocket object and provides functions for interacting with it.
  class Session < EventMachine::Connection
    using RuneRb::Patches::IntegerRefinements
    using RuneRb::Patches::StringRefinements

    include RuneRb::Utils::Logging

    include Helpers::Handshake
    include Helpers::Dispatcher
    include Helpers::Parser

    # @!attribute [r]
    # @return [Hash] a map of cipher data.
    attr :cipher

    # @!attribute [r]
    # @return [Hash] a map of Time database for the session.
    attr :duration

    # @!attribute [r] handshake
    # @return [Hash] handshake related data.
    attr :handshake

    # @!attribute [r] ip
    # @return [String, IPAddr, Addrinfo] the IPV4 address that corresponds to the underlying <@socket> object.
    attr :ip

    # @!attribute [r] sig
    # @return [Integer] the Session signature.
    attr :sig

    # @!attribute [r] stage
    # @return [Symbol] the current stage.
    attr_accessor :stage

    def post_init
      _, @ip = Socket.unpack_sockaddr_in(get_peername)
      @sig = Druuid.gen
      @buffer = RuneRb::IO::Buffer.new('rw')
      @cipher = { seed: @sig & (0xFFFFFFFF / 2) }
      @stage = :connection
      @duration = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), start: Time.now }
      log! COLORS.green.bold("New Session created @ #{@ip}")
    end

    # Pushes data read from the socket to the buffer.
    # @param data [String] the received data.
    def receive_data(data)
      @buffer.push(data)
    rescue StandardError => e
      err 'An error occurred while receiving data!', e.message
      err e.backtrace&.join("\n")
    ensure
      process
    end

    # Is the Session closed?
    # @return [Boolean]
    def closed?
      @closed
    end

    # Registers a Context to the Session.
    # @param ctx [RuneRb::Game::Entity::Context] the Context to register
    def register_context(ctx)
      @context = ctx
    end

    # The current up-time for the session.
    # @param formatted [Boolean] format the time?
    def up_time(formatted: true)
      up = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @duration[:time]).round(3).to_i
      formatted ? up.to_ftime : up
    end

    def inspect
      COLORS.blue("[SIGNATURE:] #{COLORS.cyan.bold(@sig)} || [IP:] #{COLORS.cyan.bold(@ip)} || [UP:] #{COLORS.cyan.bold(up_time)} || [LOGIN_STAGE:] #{COLORS.cyan.bold(@stage)} || [ACTIVE:] #{!closed?}" )
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
      @stage = :logged_out
      @closed = true
      close_connection_after_writing
      log! inspect
    end

    private

    # Processes data from the buffer.
    def process
      if closed?
        disconnect(:manual)
      else
        case @stage
        when :connection then read_connection
        when :handshake
          read_handshake
          @cipher[:incoming] = RuneRb::Network::ISAAC.new(@handshake[:seed].seed_array)
          @cipher[:outgoing] = RuneRb::Network::ISAAC.new(@handshake[:seed].seed_array.map { |idx| idx + 50})
          @stage = :authenticate
        when :logged_in then parse(next_message(@buffer, @cipher[:incoming])) until @buffer.data.empty?
        else nil
        end
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