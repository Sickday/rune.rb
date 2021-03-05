# Copyright (c) 2020, Patrick W.
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

module RuneRb::Game::World
  # A World Instance object models a virtual game world. The Instance object manages mobs, events, and most of all the game logic processing.
  class Instance
    using RuneRb::System::Patches::SetRefinements
    using RuneRb::System::Patches::IntegerRefinements

    include RuneRb::System::Log
    include Authorization
    #include Pipeline

    # @return [Hash] a map of entities the Instance has spawned
    attr :entities

    # @return [Integer] the id of the world instance
    attr :id

    # @return [Hash] a map of settings for the World instance.
    attr :settings

    # Called when a new World Instance is created
    def initialize
      setup
      @pulse.execute
      log 'New World Instance initialized!'
    end

    # Removes a context mob from the Instance#entities hash, then calls Context#logout on the specified mob to ensure a logout is performed.
    # @param context [RuneRb::Game::Entity::Context] the context mob to release
    def release(context)
      # Remove the context from the entity list
      @entities[:players].delete(context.index)
      # Logout the context.
      context.logout
      log RuneRb::GLOBAL[:COLOR].green.bold("Released Context for #{RuneRb::GLOBAL[:COLOR].yellow(context.profile[:name].capitalize)}") if RuneRb::GLOBAL[:DEBUG]
      log RuneRb::GLOBAL[:COLOR].magenta("See ya, #{RuneRb::GLOBAL[:COLOR].yellow(context.profile[:name].capitalize)}!")
    rescue StandardError => e
      err 'An error occurred while releasing context!', e
      puts e.backtrace
    end

    # Requests actions for the world to perform.
    # @param type [Symbol] the type of request
    # @param params [Hash] the parameters for the request.
    def request(type, params = {})
      case type
      when :local_contexts
        @entities[:players].values.select { |ctx| params[:context].position[:current].in_view?(ctx.position[:current]) }
      when :local_mobs
        @entities[:mobs].values.select { |mob| params[:context].position[:current].in_view?(mob.position[:current]) }
      when :spawn_mob
        @entities[:mobs] << RuneRb::Game::Entity::Mob.new(params[:definition]).teleport(params[:position])
      when :context
        @entities[:players].values.detect { |ctx| ctx.profile.name == params[:name] }
      else err "Unrecognized request type for world Instance! #{type}"
      end
    rescue StandardError => e
      err 'An error occurred while processing request!', e
      puts e.backtrace
    end

    # Creates a context mob, adds the mob to the Instance#entities hash, assigns the mob's index, then calls Context#login providing the Instance as the parameter
    #   # Receives a session and attempts to register it to the World Instance.
    #   # @param session [RuneRb::Network::Session] the session that is attempting to login
    # @param session [RuneRb::Net::Session] the session session for the context
    def receive(session)
      return unless authorized?(session)

      ctx = RuneRb::Game::Entity::Context.new(session, RuneRb::Database::PlayerProfile.fetch_profile(session.login[:Credentials]), self)
      ctx.index = @entities[:players].empty? ? 1 : @entities[:players].keys.last + 1
      @entities[:players][ctx.index] = ctx
      ctx.login
      log RuneRb::GLOBAL[:COLOR].green("Registered new Context for #{RuneRb::GLOBAL[:COLOR].yellow(ctx.profile[:name].capitalize)}") if RuneRb::GLOBAL[:DEBUG]
      log RuneRb::GLOBAL[:COLOR].green("Welcome, #{RuneRb::GLOBAL[:COLOR].yellow.bold(ctx.profile[:name].capitalize)}!")
    rescue StandardError => e
      err 'An error occurred while receiving context!', e
      puts e.backtrace
    end

    def inspect
      "#{RuneRb::GLOBAL[:COLOR].green("[Title]: #{RuneRb::GLOBAL[:COLOR].yellow.bold(@settings[:LABEL])}")}\n#{RuneRb::GLOBAL[:COLOR].green("[Players]: #{RuneRb::GLOBAL[:COLOR].yellow.bold(@entities[:players].size)}/#{@settings[:MAX_PLAYERS]}]")}\n#{RuneRb::GLOBAL[:COLOR].green("[Mobs]: #{RuneRb::GLOBAL[:COLOR].yellow.bold(@entities[:mobs].size)}/#{@settings[:MAX_MOBS]}]")}"
    end

    # Shut down the world instance, releasing it's contexts.
    def shutdown(graceful: true)
      # release all contexts
      @pulse.shutdown
      @entities[:players].each_value { |context| release(context) } if graceful
      @status = :CLOSED
      # RuneRb::World::Instance.dump(self) if graceful
    ensure
      log! "Total Instance Up-time: #{up_time.to_i.to_ftime}"
    end

    # The current up-time for the server.
    def up_time
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time] || Time.now)).round(3)
    end

    private

    # Initializes and loads configuration settings for the World.
    def setup
      raw_data = Oj.load(File.read('assets/config/rrb_world.json'))

      @settings = {}.tap do |hash|
        hash[:label] = raw_data['LABEL'] || "WORLD_" + Druuid.gen
        hash[:max_players] = raw_data['MAX_PLAYERS'].to_i
        hash[:max_mobs] = raw_data['MAX_MOBS'].to_i
        hash[:default_mob_x] = raw_data['DEFAULT_MOB_X'].to_i
        hash[:default_mob_y] = raw_data['DEFAULT_MOB_Y'].to_i
        hash[:default_mob_z] = raw_data['DEFAULT_MOB_Z'].to_i
        hash[:private?] = raw_data['PRIVATE'] ? true : false
      end.freeze
      @entities = { players: {}, mobs: {} }
      @responses = {}
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      @pulse = Concurrent::TimerTask.new(execution_interval: 0.600) do
        @entities[:players].each_value do |context|
          break if @entities[:players].values.empty?

          context.pre_pulse
          context.pulse
          context.post_pulse
        end
      end
    rescue StandardError => e
      err "An error occurred while running setup!", e
      err e.backtrace&.join("\n")
    end
  end
end
