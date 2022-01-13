module RuneRb::Game::Entity

  # A Mob that is representing the context of a connected Session.
  class Context < RuneRb::Game::Entity::Mob
    include RuneRb::Utils::Logging
    include RuneRb::Game::Entity::Helpers::Equipment
    include RuneRb::Game::Entity::Helpers::Inventory
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

    # @!attribute [r] stats
    # @return [RuneRb::Database::PlayerStats]
    attr :stats

    # @!attribute [r] world
    # @return [RuneRb::Game::World::Instance] the world Instance the Context is registered to.
    attr :world

    # Constructs a new Context entity.
    # @param session [RuneRb::Network::Session] the session to be associated with the entity.
    # @param profile [RuneRb::Database::PlayerProfile] the profile that will act as the definition for the context mob.
    # @param world [RuneRb::Game::World::Instance] the world instance the context is attached to/observed by.
    def initialize(session, profile, world)
      @session = session
      @profile = profile
      @world = world
      super(profile)
    end

    # Performs a series of tasks associated with deserializing and saving player information to relevant datastores.
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
      @session.write_message(:LogoutMessage, @session)

      # Detach from the world.
      @world&.release(self)
      log! 'Detached from World instance!' if RuneRb::GLOBAL[:DEBUG]
    end

    # Performs a series of task related with constructing and initializing a context's data and attaching the context to the <@world> instance.
    def login(first: true)
      @session.register_context(self)
      log! "Attached to Session #{@session.id}!" if RuneRb::GLOBAL[:DEBUG]
      # load_status
      load_appearance
      # load_inventory(first)
      # load_equipment(first)
      load_commands
      # load_stats

      # @session.write_message(:MembersAndIndexMessage, members: @status.members, player_idx: @index)
      @session.write_message(:MembersAndIndexMessage, members: 1, index: @index) # temporary
      # @session.write_message(:UpdateItemsMessage, data: @inventory[:container].data, size: 28)
      @session.write_message(:SystemTextMessage, message: 'Check the repository for updates! http://git.repos.pw/rune.rb/old')
      @session.write_message(:SystemTextMessage, message: "VERSION: #{RuneRb::GLOBAL[:ENV].build}")
      @session.auth[:stage] = :logged_in

      # update(:stats)
      update(:sidebars)
    end

    # @return [String] an inspection of the Context
    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
      str << "[POSITION]: #{@position.inspect}"
    end

    # Dispatches a ContextSynchronizationMessage to the <@session> assuming the Context meets the requirements for doing so. If a region change is needed, a CenterRegionMessage is written before the ContextSynchronizationMessage.
    def sync
      # Write region message if an update is required.
      @session.write_message(:CenterRegionMessage, @regional) if @flags[:region?]

      # Write synchronization message.
      @session.write_message(:ContextSynchronizationMessage, self) if @world && @session.status[:auth] == :LOGGED_IN && @session.status[:active]
    end

    # Initializes Appearance for the Context.
    def load_appearance
      @appearance = @profile.appearance
      update(:state)
    end

    # Initializes Stats for the Context.
    def load_stats
      @stats = @profile.stats
      update(:state)
    end

    # Initializes Status for the Context.
    def load_status
      @status = @profile.status
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