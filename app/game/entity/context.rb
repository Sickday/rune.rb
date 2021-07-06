module RuneRb::Game::Entity

  # A Mob that is representing the context of a connected Session.
  class Context < Mob
    include Helpers::Inventory
    include Helpers::Equipment
    include Helpers::Command
    include Helpers::Status
    include Helpers::Stats
    include Helpers::Queue

    # @!attribute [r] equipment
    attr :equipment

    # @!attribute [r] inventory
    # @return [RuneRb::Game::Item::Container] a container for inventory data.
    attr :inventory

    # @!attribute [r] session
    # @return [RuneRb::Network::Session] an object encapsulating a connected socket.
    attr :session


    # @!attribute [r] appearance
    # @return [RuneRb::Database::Player::Appearance] an object modeling a row within the <GLOBAL[:PLAYER_APPEARANCES]> dataset.
    attr :appearance

    # @!attribute [r] profile
    # @return [RuneRb::Database::Player::Profile] an object modeling a row within the <GLOBAL[:PLAYER_PROFILES]> dataset.
    attr :profile

    # @!attribute [r] settings
    # @return [RuneRb::Database::Player::Settings] an object modeling a row within the <GLOBAL[:PLAYER_SETTINGS]> dataset.
    attr :settings

    # @!attribute [r] status
    # @return [RuneRb::Database::Player::Status] an object modeling a row within the <GLOBAL[:PLAYER_STATUS]> dataset.
    attr :status

    # @!attribute [r] stats
    # @return [RuneRb::Database::Player::Stats] an object modeling a row within the <GLOBAL[:PLAYER_STATS]> dataset.
    attr :stats

    # @!attribute [r] world
    # @return [RuneRb::Game::World::Instance] the world Instance the Context is registered to.
    attr :world


    # @!attribute [r] forced_chat
    # @return [String] a message the context will be forced to display.
    attr :forced_chat

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
      # Detach from the world.
      @world.release(self)

      # Dump the inventory data
      dump_inventory if @inventory

      # Dump the equipment data
      dump_equipment if @equipment

      # Set the position.
      @profile.location.set(@position[:current])

      # Post the session
      @profile.status.post_session({ ip: @session.ip, duration: @session.duration[:duration] })

      # Write the actual logout.
      @session.write_message(:LogoutMessage, @session)

      log! "#{@profile[:name].capitalize} has logged out."
    end

    # Performs a series of task related with constructing and initializing a context's data and attaching the context to the <@world> instance.
    def login(first: true)
      @session.register_context(self)
      log! "Attached to Session #{@session.id}!" if RuneRb::GLOBAL[:DEBUG]
      load_inventory(first)
      load_equipment(first)
      load_status
      load_appearance
      load_commands
      load_stats
      setup_queues
      @session.status[:auth] = :LOGGED_IN
    end

    # @return [String] an inspection of the Context
    def inspect
      str = super
      str << "[INVENTORY]: #{@inventory.inspect}"
      str << "[POSITION]: #{@position.inspect}"
    end

    # Dispatches a ContextSynchronizationMessage to the <@session> assuming the Context meets the requirements for doing so. If a region change is needed, a CenterRegionMessage is written before the ContextSynchronizationMessage.
    def sync
      log! "Synchronizing..."
      logout if @session.socket.closed? || !@session.status[:active] || @session.status[:auth] == :LOGGED_OUT

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