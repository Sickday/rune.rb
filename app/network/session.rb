module RuneRb::Network
  # A Session object encapsulates a connected TCPSocket object and provides functions for interacting with it.
  class Session
    include RuneRb::Base::Utils::Logging
    include Handshake
    include Dispatcher
    include Parser

    using RuneRb::Base::Patches::IntegerRefinements

    # @!attribute [r]
    # @return [Integer] the Session ID.
    attr :id

    # @!attribute [r]
    # @return [String, IPAddr, Addrinfo] the IPV4 address that corresponds to the underlying <@socket> object.
    attr :ip

    # @!attribute [r]
    # @return [Hash] hash containing status information for the Session.
    attr :status

    attr :socket

    attr :process

    # @!attribute [r]
    # @return [Hash] a map of Time database for the session.
    attr :duration

    def initialize(socket)
      @id = Druuid.gen
      @socket = socket
      @ip = @socket.addr.last
      @duration = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), start: Time.now }
      @status = { auth: :PENDING_CONNECTION, active: true }
      @process = Fiber.new do
        loop do
          break if closed?

          case @status[:auth]
          when :PENDING_CONNECTION then read_connection
          when :PENDING_BLOCK then read_block
          when :LOGGED_IN then parse(decode(next_message(@socket)))
          #else disconnect(:auth)
          end
          # We make sure we're always yielding the <@process> passing the <@status[:active]> back to the calling endpoint.
          Fiber.yield(@status[:active])
        rescue IO::WaitReadable, IO::WaitWritable, EOFError
          # Yield the fiber if there's no data to read
          Fiber.yield(@status[:active])
        rescue RuneRb::Base::Errors::UnrecognizedMessage
          # DO NOTHING
        rescue IOError
          disconnect(:io_error)
          break
        rescue Errno::ECONNABORTED, Errno::ECONNRESET, Errno::EPIPE
          disconnect(:peer)
          break
        end
      end
      log! inspect
    end

    def send_data(data)
      @socket.write_nonblock(data)
    rescue IO::WaitReadable, IO::WaitWritable, EOFError
      # Yield the fiber if we cant write
      Fiber.yield(@status[:active])
      disconnect(:io_error)
    rescue Errno::ECONNABORTED, Errno::ECONNRESET, Errno::EPIPE
      disconnect(:peer)
      err! "An IOError prevented writing of payload <<#{data}>>"
    rescue IOError
      log! "IOError occurred during write of payload <<#{data}>>"
      disconnect(:io_error)
    end

    # Registers a Context to the Session.
    # @param ctx [RuneRb::Game::Entity::Context] the Context to register
    def register_context(ctx)
      @context = ctx
    end

    # The current up-time for the session.
    def up_time(formatted: true)
      up = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@duration[:time] || Time.now)).round(3)).to_i
      formatted ? up.to_ftime : up
    end

    def inspect
      RuneRb::GLOBAL[:COLOR].blue("[IP:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(@ip)} || [ID:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(@id)} || [UP:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(up_time)} || [STATUS:] #{RuneRb::GLOBAL[:COLOR].cyan.bold(@status.inspect)}")
    end

    def closed?
      @closed
    end

    # Ends the session closing it's socket and updating the <@status[:auth]> to :LOGGED_OUT.
    # @param reason [Symbol] the reason for the disconnect. Exclusively used for logging purposes.
    def disconnect(reason = :manual)
      @context.logout if @status[:auth] == :LOGGED_IN
      case reason
      when :logout then log! RuneRb::GLOBAL[:COLOR].green.bold("Session ended by client.")
      when :authentication, :auth then err "Session disconnected during authentication."
      when :io_error then err "Session disconnected due to IO error."
      when :handshake then err "Session disconnected during handshake."
      when :manual then err "Session forcefully closed by Endpoint. This is typically caused by a closed socket."
      when :peer then err "Session forcefully closed by peer. This could be ECONNABORTED or ECONNRESET."
      else err "Session disconnected for reason: #{reason}"
      end
      @status[:auth] = :LOGGED_OUT
    ensure
      @socket.close unless @socket.closed?
      @status[:active] = false
      @closed = true
      log! "Up-time: #{up_time(formatted: true)}", to_file: false
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