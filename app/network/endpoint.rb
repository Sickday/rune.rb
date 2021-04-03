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

module RuneRb::Network

  # An Endpoint object accepts Socket connections via TCP/IP, creates RuneRb::Network::Session objects from the accepted TCPSockets, and then transfers context to the RuneRb::Network::Session to allow them to process their updates.
  # @author Patrick W.
  class Endpoint
    using RuneRb::System::Patches::IntegerRefinements
    include RuneRb::System::Log

    # @!attribute [r] id
    # @return [Integer] the id for the Endpoint.
    attr :id

    # @!attribute [r] settings
    # @return [Hash] the settings for the Endpoint.
    attr :settings

    # @!attribute [r] node
    # @return [Fiber] the Fiber executing the main logic of the Endpoint.
    attr :node

    # Constructs a new Endpoint object
    # == Parameters:
    #   node:
    #     The Node which the Endpoint will be attached to.
    #   config:
    #     The configuration options for the Endpoint object.
    def initialize
      parse_config
      setup_pipeline
      @world = RuneRb::Game::World::Instance.new
      @server = TCPServer.new(@host, @port)
      @sessions = {}
      @node = Fiber.new do
        loop do
          break if @closed

          @pipeline[:process].resume
        end
      end
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      log RuneRb::GLOBAL[:COLOR].blue("Endpoint constructed: #{RuneRb::GLOBAL[:COLOR].cyan(@host)}:#{RuneRb::GLOBAL[:COLOR].cyan(@port)} @ #{RuneRb::GLOBAL[:COLOR].cyan(@start[:stamp])}")
    end

    # The current up-time for the Endpoint.
    #
    # @return [Integer, Float] the current up-time for the Endpoint.
    def up_time
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time] || Time.now)).round(3)
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
      log! "Up-time: #{up_time.to_i.to_ftime}"
    ensure
      @server.close
      @closed = true
    end

    private

    # Parses the configuration supplied on Endpoint construction
    # @api private
    def parse_config
      config = Oj.load(File.read('assets/config/endpoint.json'))
      @id = config['ID'].to_i || Druuid.gen
      @host = config['HOST'] || 'localhost'
      @port = config['PORT'].to_i || 43594
    end

    # Releases a Session from the Endpoint.
    #
    # @param session [RuneRb::Network::Session] the Session to release.
    def release(session)
      log! "Ending session #{session.id}"
      session.disconnect(:manual) unless session.nil? || session.status[:active] == false
      @sessions.delete(session)
    end

    def setup_pipeline
      @pipeline = {
        accept: Fiber.new do
          loop do
            socket = @server.accept_nonblock
            @sessions[socket] = RuneRb::Network::Session.new(socket)
            log! "Accepted connection from #{@sessions[socket].ip}"
          rescue IO::WaitReadable
            Fiber.yield
          end
        end,
        update: Fiber.new do |socket|
          loop do
            @sessions[socket].node.resume
            @world.receive(@sessions[socket]) if @sessions[socket].status[:auth] == :PENDING_WORLD
            release(@sessions[socket]) unless @sessions[socket].status[:active]
            Fiber.yield
          end
        end,
        process: Fiber.new do
          loop do
            # The Socket may be raised again after we've read the connection info, but either way, this will raise ANY sockets with data waiting.
            # Gather and disconnect sessions whose sockets are already closed prior to select operation
            pre_closed_sockets = @sessions.keys.collect do |socket|
              next if socket.is_a?(TCPServer)

              socket.closed?
            end
            pre_closed_sockets&.each { |socket| release(@sessions[socket]) unless socket.nil? || @sessions[socket].nil? }

            # Perform select operation for Readable interests.
            readable_sockets = select(@sessions.keys + [@server])&.first
            readable_sockets&.each do |socket|
              if socket.is_a?(TCPServer)
                @pipeline[:accept].resume(socket)
              else
                @pipeline[:update].resume(socket)
              end
            end

            Fiber.yield
          end
        end
      }.freeze
    end
  end
end
