module RuneRb::Network
  # A Session object encapsulates a connected TCPSocket object and provides functions for interacting with it.
  class Session < EventMachine::Connection
    using RuneRb::System::Patches::IntegerRefinements
    using RuneRb::System::Patches::StringRefinements

    include RuneRb::System::Log
    include Handshake
    include Dispatcher
    include Parser

    # @!attribute [r]
    # @return [Integer] the Session ID.
    attr :id

    # @!attribute [r]
    # @return [String, IPAddr, Addrinfo] the IPV4 address that corresponds to the underlying <@socket> object.
    attr :ip

    # @!attribute [r]
    # @return [Hash] hash containing status information for the Session.
    attr :status

    # @!attribute [r]
    # @return [Hash] a map of Time database for the session.
    attr :start

    def post_init
      @status = { auth: :PENDING_CONNECTION, active: true }
      _, @ip = Socket.unpack_sockaddr_in(get_peername)
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      @id = Druuid.gen
      @buffer = String.new
      log! "Session initialized!"
      log! inspect
    end

    def receive_data(data)
      @buffer << data
      case @status[:auth]
      when :PENDING_CONNECTION then read_connection
      when :PENDING_BLOCK then read_block
      when :LOGGED_IN, :PENDING_WORLD, :TRANSFERRING then next_message
      else read_connection
      end
    end

    # Registers a Context to the Session.
    # @param context [RuneRb::Game::Entity::Context] the Context to register
    def register(context)
      @context = context
    end

    # The current up-time for the session.
    def up_time(formatted: true)
      up = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time] || Time.now)).round(3)).to_i
      formatted ? up.to_ftime : up
    end

    def inspect
      RuneRb::GLOBAL[:COLOR].blue("[IP:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)} || [ID:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(@id)} || [UP:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(up_time)} || [STATUS:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(@status.inspect)}")
    end

    # Ends the session closing it's socket and updating the <@status[:auth]> to :LOGGED_OUT.
    # @param reason [Symbol] the reason for the disconnect. Exclusively used for logging purposes.
    def disconnect(reason = :manual)
      case reason
      when :logout then log! RuneRb::GLOBAL[:COLOR].green.bold("Session ended by client.")
      when :authentication then err "Session disconnected during authentication."
      when :io_error then err "Session disconnected due to IO error."
      when :handshake then err "Session disconnected during handshake."
      when :manual then err "Session forcefully closed by Endpoint. This is typically caused by a closed socket."
      when :peer then err "Session forcefully closed by peer. This could be ECONNABORTED or ECONNRESET."
      else err "Session disconnected for reason: #{reason}"
      end
      @status[:auth] = :LOGGED_OUT
    ensure
      @status[:active] = false
      log! inspect
      close_connection_after_writing
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