module RuneRb::Game::World
  # A World Instance object models a virtual game world. The Instance object manages mobs, events, and most of all the game logic processing.
  class Instance
    using RuneRb::Patches::SetRefinements
    using RuneRb::Patches::IntegerRefinements

    include RuneRb::Utils::Logging
    include Pipeline
    include Synchronization
    include Singleton

    # @!attribute [r] closed
    # @return [Boolean, NilClass] is the instance closed?
    attr :closed

    # @!attribute [r] players
    # @return [SortedSet] a collection of Contexts for players.
    attr :players

    # @!attribute [r] properties
    # @return [Struct] a map of properties for the World instance.
    attr :properties

    # @!attribute [r] sync
    # @return [Hash] a collection of synchronization objects.
    attr :sync

    # Called when a new World Instance is created
    def initialize
      @players = SortedSet.new
      @mobs = []
      @responses = {}
      @properties = Properties.new(Druuid.gen, ENV['RRB_GAME_MAX_CONTEXTS'].to_i, ENV['RRB_GAME_MAX_MOBS'].to_i)
      @properties.freeze
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
      init_sync
      init_executors
    end

    def inspect
      "#{COLORS.green("[Signature]: #{COLORS.yellow.bold(@properties.signature)}")} || #{COLORS.green("[Players]: #{COLORS.yellow.bold(@players.length)}/#{@properties.max_contexts}]")} || #{COLORS.green("[Mobs]: #{COLORS.yellow.bold(@mobs.length)}/#{@properties.max_mobs}]")}"
    end

    # Receives a session and attempts to authorize the login attempt. If the session is valid, a Context entity is created and added to the <@entities> collection. If the session is invalid, an appropriate response is dispatched to the session before the connection is closed by the session.
    # @param session [RuneRb::Network::Session] the session that is attempting to login
    def receive(session, profile, first_login: false)
      raise IndexError, "Existing context with profile for #{profile.username}" if @players.any? { |player| player.profile == profile }

      ctx = RuneRb::Game::Entity::Context.new(session, profile)
      ctx.login(self, first_login: first_login)
      log! COLORS.green.bold("Created new Context for #{COLORS.yellow.bold(profile.username.capitalize)}.")
      log! COLORS.green.bold(first_login ? "#{COLORS.yellow(profile.username.capitalize)} joined for the first time!" : "Welcome back, #{COLORS.yellow(profile.username.capitalize)}!")
    rescue IndexError => e
      log! COLORS.red.bold("An error occurred while receiving profile!"), e.message
    end

    # Removes a context mob from the Instance#entities hash, then calls Context#logout on the specified mob to ensure a logout is performed.
    # @param context [RuneRb::Game::Entity::Context] the context mob to release
    def release(context)
      @players.delete(context)
      log COLORS.green.bold("Released Context for #{COLORS.yellow(context.profile.username.capitalize)}") unless ENV['RRB_DEBUG'].nil?
      log COLORS.magenta("See ya, #{COLORS.yellow(context.profile.username.capitalize)}!")
    end

    # Shut down the world instance, releasing it's contexts.
    def shutdown(graceful: true)
      # release all contexts
      @players.each do |context|
        context.logout
        release(context)
      end if graceful

      # Shutdown pulse executor
      @executors[:pulse].shutdown

      # RuneRb::World::Instance.dump(self) if graceful
    ensure
      @closed = true
      log! "Total Instance Up-time: #{up_time}"
    end

    def closed?
      @closed
    end

    # The current up-time for the server.
    def up_time
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time])).round(3).to_i.to_ftime
    end

    private

    Properties = Struct.new(:signature, :max_contexts, :max_mobs, :login_limit)
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
