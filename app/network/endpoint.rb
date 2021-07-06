module RuneRb::Network

  # An Endpoint object accepts Socket connections via TCP/IP, creates RuneRb::Network::Session objects from the accepted TCPSockets, and then transfers context to the RuneRb::Network::Sessions.
  # @author Patrick W.
  class Endpoint
    using RuneRb::Base::Patches::IntegerRefinements
    include RuneRb::Base::Utils::Logging

    # @!attribute [r] id
    # @return [Integer] the id for the Endpoint.
    attr :id

    # @!attribute [r] target
    # @return [Array, RuneRb::Game::World::Instance] a collection of Sessions waiting to be authenticated by a World gateway
    attr :target

    # @!attribute [r] sessions
    # @return [Hash] a collection of sessions
    attr :sessions

    # Constructs a new Endpoint object
    # == Parameters:
    #   target:
    #     The target which will receive sessions from the Endpoint.
    def initialize(target: nil)
      @id =  Druuid.gen
      @host = '127.0.0.1'
      @port = 43594
      @server = TCPServer.new(@host, @port)
      @sessions = {}
      @target = target || []
      @duration = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      setup_pipeline
      log RuneRb::GLOBAL[:COLOR].blue("Endpoint constructed: #{RuneRb::GLOBAL[:COLOR].cyan(@host)}:#{RuneRb::GLOBAL[:COLOR].cyan(@port)} @ #{RuneRb::GLOBAL[:COLOR].cyan(@duration[:stamp])}")
    end

    def start_pipeline
      @pipeline[:select].resume
    end

    # Sets a new target for sessions.
    def target=(new)
      log! ""
      if new&.methods.include?(:include?)
        if @target.is_a?(Array)
          @target&.each { |session| new << session }
          @target.clear
        elsif @target.is_a?(RuneRb::Game::World::Instance)
          err! "Setting target to new world instance is unsupported!"
          return
          # TODO: implement graceful world transfer
          # @target.transfer(new)
        end
      else
        err "Invalid target set! #{new.inspect}, missing #include?(obj) in #{new.methods}"
      end
      @target = new
    end

    # The current up-time for the Endpoint.
    #
    # @return [Integer, Float] the current up-time for the Endpoint.
    def up_time(formatted: true)
      up = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@duration[:time] || Time.now)).round(3)).to_i
      formatted ? up.to_ftime : up
    end


    # Closes the Endpoint.
    # == Parameters:
    #   graceful:
    #     Should a graceful shutdown be attempted? This will attempt to cleanly close all attached Session objects before closing the <@server> and <@selector> objects.
    #
    #
    # @param graceful [Boolean] Should a graceful shutdown be attempted?
    def shutdown(graceful: true)
      @sessions.each_key(&:close) if graceful
      log! RuneRb::GLOBAL[:COLOR].green("Up-time: #{up_time(formatted: true)}")
    ensure
      close
    end

    def close
      @server.close unless @server.closed?
      @closed = true
    end

    def closed?
      @closed
    end

    private

    # Releases a Session from the Endpoint.
    #
    # @param session [RuneRb::Network::Session] the Session to release.
    def release(session)
      session.disconnect(:manual) unless session.nil?
      @sessions.delete(session)
      log "Closed #{session.inspect}"
    end

    def setup_pipeline
      @pipeline = {}.tap do |pl|
        pl[:select] = Fiber.new do
          loop do
            pre_closed = @sessions.keys.reduce(&:closed?)
            pre_closed&.each { |socket| release(@sessions[socket]) }

            result = select(@sessions.keys + [@server], nil, @sessions.keys + [@server])

            unless result.first.empty?
              result.first.each do |readable_socket|

                if readable_socket.is_a?(TCPServer)
                  pl[:accept].resume
                else
                  pl[:update].resume(readable_socket)
                end
                # Clean up
                release(@sessions[readable_socket]) if readable_socket.closed? && !readable_socket.is_a?(TCPServer)

                # Transfer
                pl[:transfer].resume
              end
            end

            Fiber.yield if result.last.size.nonzero?
          end
        end

        pl[:accept] = Fiber.new do
          loop do
            socket = @server.accept_nonblock(exception: false)
            if socket.is_a?(Symbol)
              Fiber.yield
            else
              @sessions[socket] = RuneRb::Network::Session.new(socket)
              log! "New session accepted from #{@sessions[socket].ip}"
            end
          end
        end

        pl[:update] = Fiber.new do |socket|
          @sessions[socket].pipeline[:update].resume
        end

        pl[:transfer] = Fiber.new do
          loop do
            @sessions.values.collect {|session| session.status[:auth] == :PENDING_WORLD }.each do |pending|
              unless @target.include?(pending)
                log! RuneRb::GLOBAL[:COLOR].green.bold("Transferring #{pending}")
                @target << pending
              end
            end
            Fiber.yield
          end
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