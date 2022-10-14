Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'concurrent'
require 'druuid'
require 'dotenv'
require 'eventmachine'
require 'fileutils'
require 'fiber'
require 'fiber_space'
require 'logger'
require 'pastel'
require 'pry'
require 'rrb'
require 'sequel'
require 'set'
require 'singleton'
require 'socket'

# RuneRb -
#  A game server written in Ruby targeting the 2006 era (or the 317-377 protocols) of the popular MMORPG, RuneScape.
#
#
# @author Patrick W.
# @since 0.0.1
module RuneRb

  module Utils
    autoload :LegacyController,    'rrb/legacy/utils/controller'

    module Helpers
      autoload :Gateway,           'rrb/legacy/utils/helpers/gateway'
    end
  end

  module Database

    # Factory objects to generate fake data using models.
    module Factories
      autoload :PlayerProfile,     'rrb/legacy/database/factories/player/profile'

      autoload :ItemDefinition,    'rrb/legacy/database/factories/item/definition'
      autoload :ItemEquipment,     'rrb/legacy/database/factories/item/equipment'
      autoload :ItemSpawn,         'rrb/legacy/database/factories/item/spawn'

      autoload :MobDefinition,     'rrb/legacy/database/factories/mob/definition'
      autoload :MobSpawn,          'rrb/legacy/database/factories/mob/spawn'
    end

    autoload :PlayerAppearance,    'rrb/legacy/database/models/player/appearance'
    autoload :PlayerItems,         'rrb/legacy/database/models/player/items'
    autoload :PlayerAttributes,    'rrb/legacy/database/models/player/attributes'
    autoload :PlayerLocation,      'rrb/legacy/database/models/player/location'
    autoload :PlayerProfile,       'rrb/legacy/database/models/player/profile'
    autoload :PlayerSettings,      'rrb/legacy/database/models/player/settings'
    autoload :PlayerSkills,        'rrb/legacy/database/models/player/skills'

    autoload :ItemDefinition,      'rrb/legacy/database/models/item/definition'
    autoload :ItemEquipment,       'rrb/legacy/database/models/item/equipment'
    autoload :ItemSpawn,           'rrb/legacy/database/models/item/spawn'

    autoload :MobAnimations,       'rrb/legacy/database/models/mob/animations'
    autoload :MobDefinition,       'rrb/legacy/database/models/mob/definition'
    autoload :MobSpawn,            'rrb/legacy/database/models/mob/spawn'
    autoload :MobStats,            'rrb/legacy/database/models/mob/stats'

    autoload :SystemBannedNames,   'rrb/legacy/database/models/system/banned_names'
    autoload :SystemSnapshots,     'rrb/legacy/database/models/system/snapshot'

    DatabaseConfiguration = Struct.new(:player, :system, :game)

    def self.setup_database
      db = DatabaseConfiguration.new
      case ENV['RRB_STORAGE_TYPE']
      when 'sqlite'
        db.player = Sequel.sqlite(ENV['RRB_PLAYER_SQLITE_PATH'] || 'data/sample-rrb-player.sqlite', pragmata: :foreign_keys, logger: RuneRb::LOG_FILE)
        db.game = Sequel.sqlite(ENV['RRB_GAME_SQLITE_PATH'] || 'data/sample-rrb-game.sqlite', pragmata: :foreign_keys, logger: RuneRb::LOG_FILE)
        db.system = Sequel.sqlite(ENV['RRB_SYSTEM_SQLITE_PATH'] || 'data/sample-rrb-system.sqlite', pragmata: :foreign_keys, logger: RuneRb::LOG_FILE)
      when 'pg', 'postgresql', 'postgres'
        # Model plugin for JSON serialization
        Sequel::Model.plugin(:json_serializer)
        db.player = db.game = db.system = Sequel.postgres(host: ENV['RRB_PG_HOST'], port: ENV['RRB_PG_PORT'],
                                                          user: ENV['RRB_PG_USER'], password: ENV['RRB_PG_PASS'],
                                                          database: ENV['RRB_PG_DB'], logger: RuneRb::LOG_FILE)
      else raise TypeError, "Unknown RRB_STORAGE_TYPE! Expecting: sqlite pg postgresql postgres, Received: #{ENV['RRB_STORAGE_TYPE']}"
      end
      RuneRb.const_set(:GLOBAL_DATABASE, db)
    end
  end

  # Game-related objects, modules, and classes.
  module Game

    # Entity-related objects, models, and helpers.
    module Entity
      autoload :Context,              'rrb/legacy/game/entity/context'
      autoload :Mob,                  'rrb/legacy/game/entity/mob'
      autoload :Animation,            'rrb/legacy/game/entity/models/animation'
      autoload :Command,              'rrb/legacy/game/entity/models/command'
      autoload :Graphic,              'rrb/legacy/game/entity/models/graphic'
      autoload :ChatMessage,          'rrb/legacy/game/entity/models/chat_message'

      # Commands executable by an entity.
      module Commands
        autoload :Ascend,             'rrb/legacy/game/entity/commands/ascend'
        autoload :Animation,          'rrb/legacy/game/entity/commands/animation'
        autoload :Ban,                'rrb/legacy/game/entity/commands/ban'
        autoload :Descend,            'rrb/legacy/game/entity/commands/descend'
        autoload :Design,             'rrb/legacy/game/entity/commands/design'
        autoload :Graphic,            'rrb/legacy/game/entity/commands/graphic'
        autoload :Item,               'rrb/legacy/game/entity/commands/item'
        autoload :Morph,              'rrb/legacy/game/entity/commands/morph'
        autoload :Position,           'rrb/legacy/game/entity/commands/position'
        autoload :To,                 'rrb/legacy/game/entity/commands/to'
        autoload :Show,               'rrb/legacy/game/entity/commands/show'
      end

      # Helper functions and objects used by an entity
      module Helpers
        autoload :Command,              'rrb/legacy/game/entity/helpers/command'
        autoload :Equipment,            'rrb/legacy/game/entity/helpers/equipment'
        autoload :Flags,                'rrb/legacy/game/entity/helpers/flags'
        autoload :Looks,                'rrb/legacy/game/entity/helpers/looks'
        autoload :Inventory,            'rrb/legacy/game/entity/helpers/inventory'
        autoload :Movement,             'rrb/legacy/game/entity/helpers/movement'
        autoload :State,                'rrb/legacy/game/entity/helpers/state'
      end
    end

    # Models and objects related to game items.
    module Item
      autoload :Stack,                'rrb/legacy/game/item/stack'
      autoload :Container,            'rrb/legacy/game/item/container'
      autoload :Constants,            'rrb/legacy/game/item/constants'
    end

    # Virtual Game world objects, models, and helpers.
    module World
      ACTION_PRIORITIES = { HIGH: 1, MEDIUM: 2, LOW: 3 }.freeze

      autoload :Instance,             'rrb/legacy/game/world/instance'
      autoload :Pipeline,             'rrb/legacy/game/world/helpers/pipeline'
      autoload :Synchronization,      'rrb/legacy/game/world/helpers/synchronization'
      autoload :Event,                'rrb/legacy/game/world/event'
    end

    # Models, functions, and objects related to coordinating and mapping the virtual game world
    module Map
      autoload :Constants,            'rrb/legacy/game/map/constants'
      autoload :Position,             'rrb/legacy/game/map/position'
      autoload :Direction,            'rrb/legacy/game/map/direction'
      autoload :Regional,             'rrb/legacy/game/map/regional'

      include Constants
    end
  end


  # Network-related objects, models, and helpers.
  module Network
    # @!attribute [r] PROTOCOL
    # @return [Integer, String]
    PROTOCOL = ENV['RRB_PROTOCOL'] || 317

    # @!attribute [r] REVISION
    # @return [Symbol]
    REVISION = "RS#{PROTOCOL}".to_sym

    autoload :Constants,                              'rrb/legacy/network/constants'
    autoload :ISAAC,                                  'rrb/legacy/network/isaac'
    autoload :Session,                                'rrb/legacy/network/session'

    module Helpers
      autoload :Dispatcher,                           'rrb/legacy/network/helpers/dispatcher'
      autoload :Handshake,                            'rrb/legacy/network/helpers/handshake'
      autoload :Parser,                               'rrb/legacy/network/helpers/parser'
    end

    # Messages compatible with the 317 protocol of RS.
    module RS317
      autoload :CenterRegionMessage,            'rrb/legacy/network/protocol/rs317/outgoing/center_region'
      autoload :ClearInterfacesMessage,         'rrb/legacy/network/protocol/rs317/outgoing/clear_interfaces'
      autoload :ContextSynchronizationMessage,  'rrb/legacy/network/protocol/rs317/outgoing/synchronization'
      autoload :DisplayInterfaceMessage,        'rrb/legacy/network/protocol/rs317/outgoing/interface'
      autoload :DisplaySidebarMessage,          'rrb/legacy/network/protocol/rs317/outgoing/sidebar'
      autoload :DisplayOverlayMessage,          'rrb/legacy/network/protocol/rs317/outgoing/overlay'
      autoload :LogoutMessage,                  'rrb/legacy/network/protocol/rs317/outgoing/logout'
      autoload :MembersAndIndexMessage,         'rrb/legacy/network/protocol/rs317/outgoing/membership_and_index'
      autoload :SystemTextMessage,              'rrb/legacy/network/protocol/rs317/outgoing/system_text'
      autoload :UpdateItemsMessage,             'rrb/legacy/network/protocol/rs317/outgoing/update_items'
      autoload :UpdateSlottedItemMessage,       'rrb/legacy/network/protocol/rs317/outgoing/update_slotted'
      autoload :StatUpdateMessage,              'rrb/legacy/network/protocol/rs317/outgoing/stat'

      autoload :ActionClickMessage,             'rrb/legacy/network/protocol/rs317/incoming/action'
      autoload :ArrowKeyMessage,                'rrb/legacy/network/protocol/rs317/incoming/arrow'
      autoload :ButtonClickMessage,             'rrb/legacy/network/protocol/rs317/incoming/button'
      autoload :PublicChatMessage,              'rrb/legacy/network/protocol/rs317/incoming/chat'
      autoload :MouseClickMessage,              'rrb/legacy/network/protocol/rs317/incoming/click'
      autoload :CommandMessage,                 'rrb/legacy/network/protocol/rs317/incoming/command'
      autoload :ContextDesignMessage,           'rrb/legacy/network/protocol/rs317/incoming/design'
      autoload :WindowFocusMessage,             'rrb/legacy/network/protocol/rs317/incoming/focus'
      autoload :HeartbeatMessage,               'rrb/legacy/network/protocol/rs317/incoming/heartbeat'
      autoload :MouseEventMessage,              'rrb/legacy/network/protocol/rs317/incoming/mouse'
      autoload :MovementMessage,                'rrb/legacy/network/protocol/rs317/incoming/movement'
      autoload :OptionClickMessage,             'rrb/legacy/network/protocol/rs317/incoming/option'
      autoload :PingMessage,                    'rrb/legacy/network/protocol/rs317/incoming/ping'
      autoload :SwitchItemMessage,              'rrb/legacy/network/protocol/rs317/incoming/switch'
    end

    # Messages compatible with the 377 protocol of RS.
    module RS377
      autoload :CenterRegionMessage,            'rrb/legacy/network/protocol/rs377/outgoing/center_region'
      autoload :ClearInterfacesMessage,         'rrb/legacy/network/protocol/rs377/outgoing/clear_interfaces'
      autoload :ContextSynchronizationMessage,  'rrb/legacy/network/protocol/rs377/outgoing/synchronization'
      autoload :ContextStateBlock,              'rrb/legacy/network/protocol/rs377/outgoing/state'
      autoload :DisplayInterfaceMessage,        'rrb/legacy/network/protocol/rs377/outgoing/interface'
      autoload :DisplayOverlayMessage,          'rrb/legacy/network/protocol/rs377/outgoing/overlay'
      autoload :DisplaySidebarMessage,          'rrb/legacy/network/protocol/rs377/outgoing/sidebar'
      autoload :LogoutMessage,                  'rrb/legacy/network/protocol/rs377/outgoing/logout'
      autoload :MembersAndIndexMessage,         'rrb/legacy/network/protocol/rs377/outgoing/membership_and_index'
      autoload :SystemTextMessage,              'rrb/legacy/network/protocol/rs377/outgoing/system_text'
      autoload :UpdateItemsMessage,             'rrb/legacy/network/protocol/rs377/outgoing/update_items'
      autoload :UpdateSlottedItemMessage,       'rrb/legacy/network/protocol/rs377/outgoing/update_slotted'
      autoload :StatUpdateMessage,              'rrb/legacy/network/protocol/rs377/outgoing/stat'

      autoload :ActionClickMessage,             'rrb/legacy/network/protocol/rs377/incoming/action'
      autoload :ArrowKeyMessage,                'rrb/legacy/network/protocol/rs377/incoming/arrow'
      autoload :ButtonClickMessage,             'rrb/legacy/network/protocol/rs377/incoming/button'
      autoload :PublicChatMessage,              'rrb/legacy/network/protocol/rs377/incoming/chat'
      autoload :MouseClickMessage,              'rrb/legacy/network/protocol/rs377/incoming/click'
      autoload :CommandMessage,                 'rrb/legacy/network/protocol/rs377/incoming/command'
      autoload :ContextDesignMessage,           'rrb/legacy/network/protocol/rs377/incoming/design'
      autoload :WindowFocusMessage,             'rrb/legacy/network/protocol/rs377/incoming/focus'
      autoload :HeartbeatMessage,               'rrb/legacy/network/protocol/rs377/incoming/heartbeat'
      autoload :MouseEventMessage,              'rrb/legacy/network/protocol/rs377/incoming/mouse'
      autoload :MovementMessage,                'rrb/legacy/network/protocol/rs377/incoming/movement'
      autoload :OptionClickMessage,             'rrb/legacy/network/protocol/rs377/incoming/option'
      autoload :PingMessage,                    'rrb/legacy/network/protocol/rs377/incoming/ping'
      autoload :SwitchItemMessage,              'rrb/legacy/network/protocol/rs377/incoming/switch'
    end

    include Constants
  end
end

# Copyright (c) 2022, Patrick W.
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
