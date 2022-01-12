module RuneRb::System

  # Handles the launching, processing, and shutdown of RuneRb::Network::Endpoints and RuneRb::Game::World::Instance objects.
  class Controller
    include RuneRb::Utils::Logging
    include Singleton


    # @!attribute [r] sessions
    # @return [Hash] a map of session objects
    attr :sessions

    # Constructs a new Controller object
    def initialize
      @sessions = {}
      @servers = []
      @worlds = { scheduler: Concurrent::TimerSet.new(executor: :fast), instances: {} }
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
    end

    # Launches the controller, deploying world instances and endpoint instances within the EventMachine reactor.
    def autorun
      EventMachine.run do

        # Trap Interrupt (INT) signals.
        Signal.trap('INT') do
          Thread.new do
            log! COLORS.red('Caught INTERRUPT!')
            log! COLORS.red.bold('Shutting Down...')
          ensure
            shutdown(:all)
          end.join
        end

        # Trap Termination (TERM) signals.
        Signal.trap('TERM') do
          Thread.new do
            log! COLORS.red('Caught TERMINATION!')
            log! COLORS.red.bold('Shutting Down...')
          ensure
            shutdown(:all)
          end.join
        end

        # Deploy world instances
        deploy_world

        # Deploy a server to accept sessions
        deploy_server

        # Initialize a EventMachine#tick_loop for session transfers
        init_session_tick

        # Initialize a EventMachine#tick_loop to process world pipelines.
        init_world_tick

        log "Controller is running #{COLORS.bold.cyan("rune.rb-#{RuneRb::GLOBAL[:ENV].build}")} for protocol #{COLORS.bold.cyan(RuneRb::GLOBAL[:ENV].server_config.protocol)} @ #{COLORS.bold.cyan("#{RuneRb::GLOBAL[:ENV].server_config.host}:#{RuneRb::GLOBAL[:ENV].server_config.port}")}"
      end
    end

    # Logs information about the worlds, servers, and session states.
    def about
      log COLORS.green("[Sessions]:\n#{@sessions.each(&:inspect)}")
      log COLORS.green("[Servers]:\n#{@servers.each(&:inspect)}")
      log COLORS.green("[Worlds]:\n#{@worlds.each(&:inspect)}")
    end

    # Deploys a single world instance with option configuration.
    # @param config [Hash] a map of world configuration key/value pairs.
    # @return [RuneRb::Game::World::Instance] the constructed World instance.
    def deploy_world(config = RuneRb::GLOBAL[:ENV].world_config)
      inst = RuneRb::Game::World::Instance.new(config)
      @worlds[:instances][inst.properties.signature] = inst
      @worlds[:scheduler].post(0.600) { @worlds[:instances][inst.properties.signature].pulse }
      log! "Deployed new World instance. [signature: #{inst.properties.signature}]"
      inst
    end

    # Deploys a single TCP Socket Server which is managed by EventMachine.
    # @param config [Hash] a map of server configuration key/value pairs.
    # @return [Integer] the signuature which corresponds to the constructed EventMachine server.
    def deploy_server(config = RuneRb::GLOBAL[:ENV].server_config)
      sig = EventMachine.start_server(config.host, config.port, RuneRb::Network::Session) do |session|
        @sessions[session.id] = session
      end
      @servers << sig
      log! "Deployed new Server instance. [signature: #{sig}]"
      sig
    end

    # Closes objects managed by the controller.
    # @param obj [Symbol] the type of object to shutdown
    # @param params [Hash] a collection of key value pairs to help narrow the search for the object ot shutdown.
    def shutdown(obj = :all, params = {})
      case obj
      when :all
        @sessions.each_value(&:disconnect)
        sleep(1) unless @sessions.all?(&:closed?)
        log! COLORS.red.bold("Ended #{@sessions.length} sessions..")

        @worlds[:instances].each_key { |sig| shutdown(:world, signature: sig) }
        sleep(1) unless @worlds[:instances].values.all?(&:closed)
        log! COLORS.red.bold("Closed #{@worlds[:instances].length} worlds..")

        @servers.each { |sig| shutdown(:server, signature: sig) }
        log! COLORS.red.bold("Closed #{@servers.length} servers..")

        EventMachine.stop
        sleep(1) if EventMachine.reactor_running?
        log! COLORS.red.bold('Stopped EM Reactor!')
      when :world
        target = @worlds[:instances][params[:signature]]
        target ||= @worlds.detect { |world| world.properties.label = params[:label] || params[:title] }
        target.shutdown
        log! COLORS.red.bold("Closed world with signature - #{target.properties.signature}.")
      when :server
        EventMachine.stop_server(params[:signature])
        log! COLORS.red.bold("Closed server with signature - #{params[:signature]}")
      else shutdown(:all)
      end
    rescue StandardError => e
      err 'An error occurred during shutdown!', e.message
      err e.backtrace&.join("\n")
    end

    private

    # Each tick this function ensures sessions whose <status[:auth]> is equal to `:PENDING_WORLD` are logged into the next available world instance which can accept the player. This function also disconnects any lingering sessions which are no longer active.
    def init_session_tick
      EventMachine.tick_loop do
        @sessions.each_value do |session|
          @sessions.delete(session) if session.authentication.stage == :LOGGED_OUT || session.authentication.stage == :DISCONNECTED
        end

        transfers = @sessions.values.collect { |session| session.authentication.stage == :authenticate }
        destination = @worlds[:instances].values.detect { |world| world.entities[:players].length + transfers.length <= world.properties.max_contexts }
        transfers.each { |session| destination.authenticate(session) } unless destination.nil?
      end
    end

    def init_world_tick
      EventMachine.tick_loop do
        @worlds[:instances].delete_if { |_, world| world.closed }
        @worlds[:instances].each_value(&:process_pipeline)
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