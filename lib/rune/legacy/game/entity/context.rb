module RuneRb::Game::Entity

  # A Mob that is representing the context of a connected Session.
  class Context < RuneRb::Game::Entity::Mob
    include RuneRb::Utils::Logging
    include RuneRb::Game::Entity::Helpers::Equipment
    include RuneRb::Game::Entity::Helpers::Inventory
    include RuneRb::Game::Entity::Helpers::Command
    include RuneRb::Game::Entity::Helpers::State

    # @!attribute [r] session
    # @return [RuneRb::Network::Session] the Session for the Context
    attr :session

    # @!attribute [r] profile
    # @return [RuneRb::Database::PlayerProfile] the Profile of the Context which acts as it's definition.
    attr :profile

    # @!attribute [r] world
    # @return [RuneRb::Game::World::Instance] the world Instance the Context is registered to.
    attr :world

    # Constructs a new Context entity.
    # @param session [RuneRb::Network::Session] the session to be associated with the entity.
    # @param profile [RuneRb::Database::PlayerProfile] the profile that will act as the definition for the context mob.
    def initialize(session, profile)
      @session = session
      @profile = profile
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

      # Detach from the world.
      @world.release(self)

      # Post the session
      @profile.attributes.post_session(@session.ip)

      # Write the actual logout.
      @session.write_message(:LogoutMessage, @session)
    end

    # Performs a series of task related with constructing and initializing a context's data and attaching the context to the <@world> instance.
    # @param world [RuneRb::Game::World::Instance] the world instance the context is attached to.
    def login(world, first_login: false)
      attach_to(world)
      load_attr
      load_state
      load_appearance
      load_inventory(first_login: first_login)
      load_equipment(first_login: first_login)
      load_skills
      load_commands

      generate_looks
      generate_state

      @session.write_message(:MembersAndIndexMessage, members: @profile.attributes.members, player_idx: @index)
      @session.write_message(:UpdateItemsMessage, data: @inventory[:container].data, size: 28)
      @session.write_message(:SystemTextMessage, message: "Welcome to rune.rb v#{RuneRb.build}")
      @session.write_message(:SystemTextMessage, message: 'Check the repository for updates! https://git.repos.pw/rune.rb/main')
      @session.register_context(self)

      update(:sidebars)
    end

    # Effectively attaches this context to a world instance.
    # @param world [RuneRb::Game::World::Instance] the game world instance.
    def attach_to(world)
      @world = world
      @world.players << self
      @index = world.players.find_index(self)
    end

    # @return [String] an inspection of the Context
    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
      str << "[POSITION]: #{@position.inspect}"
    end

    def pre_sync
      generate_looks if looks_update?
      generate_state if state_update?
      super
    end

    # Dispatches a ContextSynchronizationMessage to the <@session> assuming the Context meets the requirements for doing so. If a region change is needed, a CenterRegionMessage is written before the ContextSynchronizationMessage.
    def sync
      # Write region message if an update is required.
      @session.write_message(:CenterRegionMessage, @regional) if @flags[:region?]

      # Write synchronization message.
      @session.write_message(:ContextSynchronizationMessage, self) if @world && @session.stage == :logged_in
    end

    def post_sync
      @animation = nil
      @graphic = nil
      @chat_message = nil
      reset_flags
      super
    end

    # Mutual comparison
    # @param other_context [RuneRb::Game::Entity::Context] the other context.
    def <=>(other_context)
      @index <=> other_context.index
    end

    private

    # Initializes Appearance for the Context.
    def load_appearance
      @appearance = @profile.appearance
      @flags[:looks?] = true
    end

    # Initializes Stats for the Context.
    def load_skills
      @stats = @profile.skills
      update(:stats)
    end

    # Initializes Status for the Context.
    def load_attr
      @attributes = @profile.attributes
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
