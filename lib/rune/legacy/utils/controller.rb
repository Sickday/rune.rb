module RuneRb::Utils

  # Handles the launching, processing, and shutdown of RuneRb::Network::Endpoints and RuneRb::Game::World::Instance objects.
  class LegacyController
    include RuneRb::Utils::Logging
    include RuneRb::Utils::Helpers::Gateway
    include Singleton

    # @!attribute [r] sessions
    # @return [Hash] a map of session objects
    attr :sessions

    # Constructs a new Controller object
    def initialize
      @sessions = {}
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
    end

    # Launches the controller, deploying world instances and endpoint instances within the EventMachine reactor.
    def autorun(console: false)
      EventMachine.run do
        # Setup EM tick
        setup_tick

        # Setup signal trapping
        setup_trapping

        # Deploy world instances
        deploy_world

        # Deploy a server to accept sessions
        deploy_server

        log "Controller is running #{COLORS.bold.cyan("rune.rb-#{RuneRb.build}")} for protocol #{COLORS.bold.cyan(RuneRb::Network::REVISION)} @ #{COLORS.bold.cyan("#{ENV['RRB_NET_HOST']}:#{ENV['RRB_NET_PORT']}")}"

        # Deploy console
        deploy_console if console
      end
    end

    # Logs information about the worlds, servers, and session states.
    def about
      log COLORS.cyan.bold("[Sessions]: #{@sessions.length}")
      log COLORS.magenta.bold("[Servers]: #{@server.inspect}")
      log COLORS.yellow.bold("[Worlds]: #{@world.inspect}")
    end

    # Deploys a pry console.
    def deploy_console
      Pry.start(self)
    end

    # Deploys a single world instance with option configuration.
    def deploy_world
      @world = RuneRb::Game::World::Instance.instance
      log! "Deployed new World instance. [signature: #{@world.properties.signature}]"
    end

    # Deploys a single TCP Socket Server which is managed by EventMachine.
    def deploy_server
      @server = EventMachine.start_server(ENV['RRB_NET_HOST'], ENV['RRB_NET_PORT'], RuneRb::Network::Session) do |session|
        @sessions[session.sig] = session
      end
      log! "Deployed new Server instance. [signature: #{@server}]"
    end

    # Closes objects managed by the controller.
    # @param obj [Symbol] the type of object to shutdown
    # @param params [Hash] a collection of key value pairs to help narrow the search for the object ot shutdown.
    def shutdown(obj = :all, params = {})
      case obj
      when :all
        @sessions.each_value(&:disconnect)
        sleep(1) unless @sessions.values.all?(&:closed?)
        log! COLORS.red.bold("Ended #{@sessions.length} sessions..")

        shutdown(:world)
        log! COLORS.red.bold("Closed World Instance.")

        shutdown(:server)
        log! COLORS.red.bold("Closed Server Instance.")

        EventMachine.stop
        sleep(1) if EventMachine.reactor_running?
        log! COLORS.red.bold('Stopped EM Reactor!')
      when :world
        @world&.shutdown(graceful: params[:graceful])
        log! COLORS.red.bold("Closed World with signature - #{@world&.properties&.signature}.")
      when :server
        EventMachine.stop_server(@server)
        log! COLORS.red.bold("Closed Server with signature - #{@server}")
      else shutdown(:all)
      end
    rescue StandardError => e
      err 'An error occurred during shutdown!', e.message
      err e.backtrace&.join("\n")
    end

    private

    # Each tick this function ensures sessions whose <status[:auth]> is equal to `:PENDING_WORLD` are logged into the next available world instance which can accept the player. This function also disconnects any lingering sessions which are no longer active.
    def setup_tick
      EventMachine.tick_loop do

        @sessions.each do |_, session|
          case session.stage
          when :logged_out, :disconnected then @sessions.delete(session) # Remove logged out or dc'd sessions
          when :authenticate then authenticate(session, @world) unless @world.nil? # Authenticate sessions that are ready for auth
          else next
          end
        end

        # Process World Events.
        @world&.process_events

        # Remove closed worlds.
        @world = nil if @world&.closed?
      end
    end

    def setup_trapping
      # Trap Interrupt (INT) signals.
      Signal.trap('INT') do
        Thread.new do
          log! COLORS.red('Caught INT signal!')
          log! COLORS.red.bold('Shutting Down Controller...')
        ensure
          shutdown(:all)
        end.join
      end

      # Trap Termination (TERM) signals.
      Signal.trap('TERM') do
        Thread.new do
          log! COLORS.red('Caught TERM signal!')
          log! COLORS.red.bold('Shutting Down Controller...')
        ensure
          shutdown(:all)
        end.join
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
