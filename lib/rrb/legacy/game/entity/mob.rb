module RuneRb::Game::Entity
  # Models a mobile model.
  class Mob
    include RuneRb::Utils::Logging
    include RuneRb::Game::Entity::Helpers::Movement
    include RuneRb::Game::Entity::Helpers::Flags

    # @return [Object] a definition object contains details about the Mobs properties. TODO: impl mob definitions.
    attr :definition

    # @return [RuneRb::Game::Entity::Animation] the current Animation of the Mob
    attr :animation

    # @return [RuneRb::Game::Entity::Graphic] the current Graphic of the Mob
    attr :graphic

    # @return [RuneRb::Game::Entity::Message] the current Message of the Mob
    attr :message

    # @return [RuneRb::Game::Map::Regional] the regional position for the mob
    attr :regional

    # @return [Integer] the index of the Mob within it's world Instance's mob list.
    attr_accessor :index

    # Constructs a new Mob object with the passed definition.
    # @param definition [Object] the Definition for the mob.
    def initialize(definition)
      register(definition)
      load_movement
    end

    # Called before a SynchronizationMessage is constructed and dispatched.
    def pre_sync
      #move
    end

    def sync; end

    # Called after a SynchronizationMessage is dispatched.
    def post_sync
      reset_movement
    end

    # Registers a definition to the Mob.
    def register(definition)
      load_definition(definition)
    end

    private

    # Initializes certain mob variables from it's definition.
    def load_definition(definition)
      @id = definition.id
      @position = { current: definition.location.to_position, previous: definition.location.to_position }
      @regional = @position[:current].regional
      @definition = definition
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