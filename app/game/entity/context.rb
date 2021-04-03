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

module RuneRb::Game::Entity
  # A Context object is a Mob that is representing the context of a connected Session.
  class Context < RuneRb::Game::Entity::Mob
    include RuneRb::System::Log
    include RuneRb::Game::Entity::Helpers::Equipment
    include RuneRb::Game::Entity::Helpers::Inventory
    include RuneRb::Game::Entity::Helpers::Button
    include RuneRb::Game::Entity::Helpers::Click
    include RuneRb::Game::Entity::Helpers::Command

    # @!attribute [r] equipment
    # @return [Hash] the Equipment database for a context.
    attr :equipment

    # @!attribute [r] inventory
    # @return [RuneRb::Game::Item::Container] the Inventory database for the Context
    attr :inventory

    # @!attribute [r] session
    # @return [RuneRb::Network::Session] the Session for the Context
    attr :session

    # @!attribute [r] appearance
    # @return [RuneRb::Database::PlayerAppearance] the appearance of the Context
    attr :appearance

    # @!attribute [r] profile
    # @return [RuneRb::Database::PlayerProfile] the Profile of the Context which acts as it's definition.
    attr :profile

    # @!attribute [r] status
    # @return [RuneRb::Database::PlayerStatus]
    attr :status

    # @!attribute [r] settings
    # @return [RuneRb::Database::PlayerSettings]
    attr :settings

    # @!attribute [r] world
    # @return [RuneRb::Game::World::Instance] the world Instance the Context is registered to.
    attr :world

    # Called when a new Context Entity is created.
    # @param session [RuneRb::Network::Session] the session to be associated with the entity.
    # @param profile [RuneRb::Database::PlayerProfile] the profile that will act as the definition for the context mob.
    def initialize(session, profile, world)
      @session = session
      @profile = profile
      @world = world
      super(profile)
    end

    # Logs the context out and detaches the context from the Context#world Instance.
    # * detaches the context from the world instance via Context#detach
    # * dumps the Context#inventory[:container]
    # * dumps the Context#equipment
    # * updates the Context#profile#location to the current Context#position
    # * closes the session via Context#session#close_connection
    def logout
      # Dump the inventory database
      dump_inventory if @inventory

      # Dump the equipment database
      dump_equipment if @equipment

      # Set the position.
      @profile.location.set(@position[:current])

      # Post the session
      @profile.status.post_session(session)

      # Write the actual logout.
      @session.write_message(:logout)

      # Detach from the world.
      @world = nil
      log! 'Detached from World instance!' if RuneRb::GLOBAL[:DEBUG]
    end

    # Logs the context in and attaches the context to a world Instance.
    # * loads the Context#appearance
    # * loads the Context#inventory
    # * loads the Context#equipment
    # * loads the Context#stats
    # * teleports the Context to Context#position
    # * assigns the Context#world
    def login
      @session.register(self)
      log! "Attached to Session #{@session.id}!" if RuneRb::GLOBAL[:DEBUG]
      load_status
      load_appearance
      load_inventory
      load_equipment
      load_commands
      load_stats
      teleport(@position[:current])
      @session.status[:auth] = :LOGGED_IN
      @session.write_message(:login)
    rescue StandardError => e
      err! 'An error occurred while attaching session to Endpoint!'
      puts e
      puts e.backtrace
    end

    # @return [String] an inspection of the Context
    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
      str << "[POSITION]: #{@position.inspect}"
    end

    def pulse
      #@session.write_message(:sync) if @session.status[:auth] == :LOGGED_IN && @session.status[:active] && @world
      log! "Sample Pulse"
    end

    # Initializes Appearance for the Context.
    def load_appearance
      @appearance = @profile.appearance
      update(:state)
    end

    # Initializes Stats for the Context.
    def load_stats
      @stats = @profile.stats
      @session.write_message(:stats, @stats)
    end

    # Initializes Status for the Context.
    def load_status
      @status = @profile.status
    end
  end
end
