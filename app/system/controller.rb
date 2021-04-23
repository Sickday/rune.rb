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

module RuneRb::System

  # Handles the launching, processing, and shutdown of RuneRb::Network::Endpoints and RuneRb::Game::World::Instance objects.
  class Controller
    include Singleton
    include Log

    # Constructs a new Controller object
    def initialize
      @sessions = []
      @worlds = []
      @endpoints = []
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      load_configs
    end

    # Launches the controller, deploying world insstances and endpoint instances within the EventMachine reactor.
    def run
      EventMachine.run do
        # TODO: read more into what can be done while in trap context
        Signal.trap('INT') { shutdown }

        # Deploy world instances
        deploy_worlds

        # Deploy an endpoint to accept sessions
        deploy_endpoints

        # Construct tick loop to process sessions
        process_sessions
      end
    end

    # Closes endpoints, shuts down worlds and stops the EventMachine reactor.
    def shutdown
      @endpoints.each { |ep| EventMachine.stop_server(ep) }
      @worlds.each(&:shutdown)
    ensure
      EventMachine.stop
    end

    # Deploys a single world
    def deploy_worlds
      @worlds << RuneRb::Game::World::Instance.new(@configs[:world])
    end

    # Deploys a single endpoint instance
    def deploy_endpoints
      @endpoints << EventMachine.start_server(@configs[:endpoint][:HOST], @configs[:endpoint][:PORT], RuneRb::Network::Session) { |session| @sessions << session }
    end

    # Each tick this function ensures sessions whose <status[:auth]> is equal to `:PENDING_WORLD` are logged into the next available world instance which can accept the player. This function also disconnects any lingering sessions which are no longer active.
    def process_sessions
      EventMachine.tick_loop do
        transfer_batch = @sessions.select { |session| session.status[:auth] == :PENDING_WORLD }
        destination = @worlds.detect { |world| world.entities[:players].length + transfer_batch.length <= world.settings[:max_players] }

        unless destination.nil?
          transfer_batch.each do |session|
            session.status[:auth] = :TRANSFERRING
            destination.receive(session)
          end
        end

        inactive_batch = @sessions.select { |session| session.status[:active] == false || session.status[:active].nil? }
        inactive_batch.each { |session| @sessions.delete(session) }
      end
    end

    # Logs information about the controller and it's assets.
    def about
      log! RuneRb::GLOBAL[:COLOR].green("[Endpoints]: #{@endpoints.length}")
      log! RuneRb::GLOBAL[:COLOR].green("[Worlds]: #{@worlds.length}")
      log! RuneRb::GLOBAL[:COLOR].green("[Endpoints]: #{@endpoints.each(&:inspect)}")
      log! RuneRb::GLOBAL[:COLOR].green("[Worlds]: #{@worlds.each(&:inspect)}")
    end

    # Deserializes and attempts to parse configuration files located in `assets/config`.
    def load_configs
      raw_ep_data = Oj.safe_load(File.read('assets/config/endpoint.json'))
      raw_world_data = Oj.safe_load(File.read('assets/config/world.json'))

      @configs = {}.tap do |hash|
        hash[:world] = {}
        hash[:world][:label] = raw_world_data['LABEL'] || "WORLD_" + Druuid.gen
        hash[:world][:max_players] = raw_world_data['MAX_PLAYERS'].to_i
        hash[:world][:max_mobs] = raw_world_data['MAX_MOBS'].to_i
        hash[:world][:default_mob_x] = raw_world_data['DEFAULT_MOB_X'].to_i
        hash[:world][:default_mob_y] = raw_world_data['DEFAULT_MOB_Y'].to_i
        hash[:world][:default_mob_z] = raw_world_data['DEFAULT_MOB_Z'].to_i
        hash[:world][:private?] = raw_world_data['PRIVATE'] ? true : false

        hash[:endpoint] = {}
        hash[:endpoint][:HOST] = raw_ep_data['HOST']
        hash[:endpoint][:PORT] = raw_ep_data['PORT']
      end
      log! "Loaded configuration."
    rescue StandardError => e
      err "An error occurred while loading config files.", e, e.backtrace.join("\n")
    end
  end
end