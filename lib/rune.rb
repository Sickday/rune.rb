Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'concurrent'
require 'druuid'
require 'dotenv'
require 'eventmachine'
require 'fileutils'
require 'fiber'
require 'logger'
require 'pastel'
require 'pry'
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
    autoload :LegacyController,    'rune/utils/controller'

    module Helpers
      autoload :Gateway,           'rune/utils/helpers/gateway'
    end
  end

  module Database

    # Factory objects to generate fake data using models.
    module Factories
      autoload :PlayerProfile,     'rune/database/factories/player/profile'

      autoload :ItemDefinition,    'rune/database/factories/item/definition'
      autoload :ItemEquipment,     'rune/database/factories/item/equipment'
      autoload :ItemSpawn,         'rune/database/factories/item/spawn'

      autoload :MobDefinition,     'rune/database/factories/mob/definition'
      autoload :MobSpawn,          'rune/database/factories/mob/spawn'
    end

    autoload :PlayerAppearance,    'rune/database/models/player/appearance'
    autoload :PlayerItems,         'rune/database/models/player/items'
    autoload :PlayerAttributes,    'rune/database/models/player/attributes'
    autoload :PlayerLocation,      'rune/database/models/player/location'
    autoload :PlayerProfile,       'rune/database/models/player/profile'
    autoload :PlayerSettings,      'rune/database/models/player/settings'
    autoload :PlayerSkills,        'rune/database/models/player/skills'

    autoload :ItemDefinition,      'rune/database/models/item/definition'
    autoload :ItemEquipment,       'rune/database/models/item/equipment'
    autoload :ItemSpawn,           'rune/database/models/item/spawn'

    autoload :MobAnimations,       'rune/database/models/mob/animations'
    autoload :MobDefinition,       'rune/database/models/mob/definition'
    autoload :MobSpawn,            'rune/database/models/mob/spawn'
    autoload :MobStats,            'rune/database/models/mob/stats'

    autoload :SystemBannedNames,   'rune/database/models/system/banned_names'
    autoload :SystemSnapshots,     'rune/database/models/system/snapshot'

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
      autoload :Context,              'rune/game/entity/context'
      autoload :Mob,                  'rune/game/entity/mob'
      autoload :Animation,            'rune/game/entity/models/animation'
      autoload :Command,              'rune/game/entity/models/command'
      autoload :Graphic,              'rune/game/entity/models/graphic'
      autoload :ChatMessage,          'rune/game/entity/models/chat_message'

      # Commands executable by an entity.
      module Commands
        autoload :Ascend,             'rune/game/entity/commands/ascend'
        autoload :Animation,          'rune/game/entity/commands/animation'
        autoload :Ban,                'rune/game/entity/commands/ban'
        autoload :Descend,            'rune/game/entity/commands/descend'
        autoload :Design,             'rune/game/entity/commands/design'
        autoload :Graphic,            'rune/game/entity/commands/graphic'
        autoload :Item,               'rune/game/entity/commands/item'
        autoload :Morph,              'rune/game/entity/commands/morph'
        autoload :Position,           'rune/game/entity/commands/position'
        autoload :To,                 'rune/game/entity/commands/to'
        autoload :Show,               'rune/game/entity/commands/show'
      end

      # Helper functions and objects used by an entity
      module Helpers
        autoload :Command,              'rune/game/entity/helpers/command'
        autoload :Equipment,            'rune/game/entity/helpers/equipment'
        autoload :Flags,                'rune/game/entity/helpers/flags'
        autoload :Looks,                'rune/game/entity/helpers/looks'
        autoload :Inventory,            'rune/game/entity/helpers/inventory'
        autoload :Movement,             'rune/game/entity/helpers/movement'
        autoload :State,                'rune/game/entity/helpers/state'
      end
    end

    # Models and objects related to game items.
    module Item
      autoload :Stack,                'rune/game/item/stack'
      autoload :Container,            'rune/game/item/container'
      autoload :Constants,            'rune/game/item/constants'
    end

    # Virtual Game world objects, models, and helpers.
    module World
      ACTION_PRIORITIES = { HIGH: 1, MEDIUM: 2, LOW: 3 }.freeze

      autoload :Instance,             'rune/game/world/instance'
      autoload :Pipeline,             'rune/game/world/helpers/pipeline'
      autoload :Synchronization,      'rune/game/world/helpers/synchronization'
      autoload :Event,                'rune/game/world/event'
    end

    # Models, functions, and objects related to coordinating and mapping the virtual game world
    module Map
      autoload :Constants,            'rune/game/map/constants'
      autoload :Position,             'rune/game/map/position'
      autoload :Direction,            'rune/game/map/direction'
      autoload :Regional,             'rune/game/map/regional'

      include Constants
    end
  end

  # Network-related objects, models, and helpers.
  module Network
    # @!attribute [r] PROTOCOL
    # @return [Integer, String]
    PROTOCOL = ENV['rune_PROTOCOL'] || 317

    # @!attribute [r] REVISION
    # @return [Symbol]
    REVISION = "RS#{PROTOCOL}".to_sym

    autoload :Constants,                              'rune/network/constants'
    autoload :ISAAC,                                  'rune/network/isaac'
    autoload :Session,                                'rune/network/session'

    module Helpers
      autoload :Dispatcher,                           'rune/network/helpers/dispatcher'
      autoload :Handshake,                            'rune/network/helpers/handshake'
      autoload :Parser,                               'rune/network/helpers/parser'
    end

    # Messages compatible with the 317 protocol of RS.
    module RS317
      autoload :CenterRegionMessage,            'rune/network/protocol/rs317/outgoing/center_region'
      autoload :ClearInterfacesMessage,         'rune/network/protocol/rs317/outgoing/clear_interfaces'
      autoload :ContextSynchronizationMessage,  'rune/network/protocol/rs317/outgoing/synchronization'
      autoload :DisplayInterfaceMessage,        'rune/network/protocol/rs317/outgoing/interface'
      autoload :DisplaySidebarMessage,          'rune/network/protocol/rs317/outgoing/sidebar'
      autoload :DisplayOverlayMessage,          'rune/network/protocol/rs317/outgoing/overlay'
      autoload :LogoutMessage,                  'rune/network/protocol/rs317/outgoing/logout'
      autoload :MembersAndIndexMessage,         'rune/network/protocol/rs317/outgoing/membership_and_index'
      autoload :SystemTextMessage,              'rune/network/protocol/rs317/outgoing/system_text'
      autoload :UpdateItemsMessage,             'rune/network/protocol/rs317/outgoing/update_items'
      autoload :UpdateSlottedItemMessage,       'rune/network/protocol/rs317/outgoing/update_slotted'
      autoload :StatUpdateMessage,              'rune/network/protocol/rs317/outgoing/stat'

      autoload :ActionClickMessage,             'rune/network/protocol/rs317/incoming/action'
      autoload :ArrowKeyMessage,                'rune/network/protocol/rs317/incoming/arrow'
      autoload :ButtonClickMessage,             'rune/network/protocol/rs317/incoming/button'
      autoload :PublicChatMessage,              'rune/network/protocol/rs317/incoming/chat'
      autoload :MouseClickMessage,              'rune/network/protocol/rs317/incoming/click'
      autoload :CommandMessage,                 'rune/network/protocol/rs317/incoming/command'
      autoload :ContextDesignMessage,           'rune/network/protocol/rs317/incoming/design'
      autoload :WindowFocusMessage,             'rune/network/protocol/rs317/incoming/focus'
      autoload :HeartbeatMessage,               'rune/network/protocol/rs317/incoming/heartbeat'
      autoload :MouseEventMessage,              'rune/network/protocol/rs317/incoming/mouse'
      autoload :MovementMessage,                'rune/network/protocol/rs317/incoming/movement'
      autoload :OptionClickMessage,             'rune/network/protocol/rs317/incoming/option'
      autoload :PingMessage,                    'rune/network/protocol/rs317/incoming/ping'
      autoload :SwitchItemMessage,              'rune/network/protocol/rs317/incoming/switch'
    end

    # Messages compatible with the 377 protocol of RS.
    module RS377
      autoload :CenterRegionMessage,            'rune/network/protocol/rs377/outgoing/center_region'
      autoload :ClearInterfacesMessage,         'rune/network/protocol/rs377/outgoing/clear_interfaces'
      autoload :ContextSynchronizationMessage,  'rune/network/protocol/rs377/outgoing/synchronization'
      autoload :ContextStateBlock,              'rune/network/protocol/rs377/outgoing/state'
      autoload :DisplayInterfaceMessage,        'rune/network/protocol/rs377/outgoing/interface'
      autoload :DisplayOverlayMessage,          'rune/network/protocol/rs377/outgoing/overlay'
      autoload :DisplaySidebarMessage,          'rune/network/protocol/rs377/outgoing/sidebar'
      autoload :LogoutMessage,                  'rune/network/protocol/rs377/outgoing/logout'
      autoload :MembersAndIndexMessage,         'rune/network/protocol/rs377/outgoing/membership_and_index'
      autoload :SystemTextMessage,              'rune/network/protocol/rs377/outgoing/system_text'
      autoload :UpdateItemsMessage,             'rune/network/protocol/rs377/outgoing/update_items'
      autoload :UpdateSlottedItemMessage,       'rune/network/protocol/rs377/outgoing/update_slotted'
      autoload :StatUpdateMessage,              'rune/network/protocol/rs377/outgoing/stat'

      autoload :ActionClickMessage,             'rune/network/protocol/rs377/incoming/action'
      autoload :ArrowKeyMessage,                'rune/network/protocol/rs377/incoming/arrow'
      autoload :ButtonClickMessage,             'rune/network/protocol/rs377/incoming/button'
      autoload :PublicChatMessage,              'rune/network/protocol/rs377/incoming/chat'
      autoload :MouseClickMessage,              'rune/network/protocol/rs377/incoming/click'
      autoload :CommandMessage,                 'rune/network/protocol/rs377/incoming/command'
      autoload :ContextDesignMessage,           'rune/network/protocol/rs377/incoming/design'
      autoload :WindowFocusMessage,             'rune/network/protocol/rs377/incoming/focus'
      autoload :HeartbeatMessage,               'rune/network/protocol/rs377/incoming/heartbeat'
      autoload :MouseEventMessage,              'rune/network/protocol/rs377/incoming/mouse'
      autoload :MovementMessage,                'rune/network/protocol/rs377/incoming/movement'
      autoload :OptionClickMessage,             'rune/network/protocol/rs377/incoming/option'
      autoload :PingMessage,                    'rune/network/protocol/rs377/incoming/ping'
      autoload :SwitchItemMessage,              'rune/network/protocol/rs377/incoming/switch'
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
