Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'druuid'
require 'eventmachine'
require 'fileutils'
require 'fiber'
require 'logger'
require 'oj'
require 'pastel'
require 'sequel'
require 'singleton'
require 'socket'

##
# RuneRb -
#  A game server written in Ruby targeting the 2006 era (or the 317-377 protocols) of the popular MMORPG, RuneScape.
#
#
# @author Patrick W.
# @since 0.9.3
module RuneRb

  # Internally used Errors, Patches, and Modules.
  module System
    autoload :Controller,           'system/controller'
    autoload :Setup,                'system/setup'
    autoload :Log,                  'system/log'

    module Errors
      autoload :ConflictingNameError,         'system/errors'
      autoload :SessionReceptionError,        'system/errors'
    end

    # Refinements made to objects already defined in the stdlib/core lib. The refinements are used in the objects who require the functions defined in the refinement. Doing this prevents pollution of the global definitions of the stdlib objects.
    module Patches
      autoload :IntegerRefinements,     'system/patches/integer'
      autoload :SetRefinements,         'system/patches/set'
      autoload :StringRefinements,      'system/patches/string'
      autoload :Readable,               'system/patches/readable'
      autoload :Writeable,              'system/patches/writeable'
    end
  end

  begin
    GLOBAL = {}.tap do |data|
      RuneRb::System::Setup.init_global_data(data)
      RuneRb::System::Setup.init_logger(data)
      data[:LOG].info 'RuneRb initializing...'
      RuneRb::System::Setup.init_game_data(data)
      data[:LOG].info 'Initialized Game database.'

      RuneRb::System::Setup.init_item_data(data)
      data[:LOG].info 'Initialized Item database.'

      RuneRb::System::Setup.init_player_data(data)
      data[:LOG].info 'Initialized Player database.'

      RuneRb::System::Setup.init_mob_data(data)
      data[:LOG].info 'Initialized Mob database.'

    end
    GLOBAL[:LOG].info GLOBAL[:COLOR].green.bold("RuneRb initialized with protocol #{GLOBAL[:COLOR].yellow(GLOBAL[:PROTOCOL])}!")
  rescue StandardError => e
    puts 'An error occurred while loading Global settings!'
    puts e
    puts e.backtrace.join("\n")
    exit
  end

  # Database model objects which map to rows within database tables.
  module Database
    autoload :GameBannedNames,            'database/models/game/banned_names'
    autoload :GameSnapshot,               'database/models/game/snapshot'

    autoload :ItemEquipment,              'database/models/item/equipment'
    autoload :ItemDefinition,             'database/models/item/definition'
    autoload :ItemSpawn,                  'database/models/item/spawn'

    autoload :MobAnimations,              'database/models/mob/animations'
    autoload :MobDefinition,              'database/models/mob/definition'
    autoload :MobSpawn,                   'database/models/mob/spawn'
    autoload :MobStats,                   'database/models/mob/stats'

    autoload :PlayerAppearance,           'database/models/player/appearance'
    autoload :PlayerProfile,              'database/models/player/profile'
    autoload :PlayerStats,                'database/models/player/stats'
    autoload :PlayerStatus,               'database/models/player/status'
    autoload :PlayerSettings,             'database/models/player/settings'
    autoload :PlayerLocation,             'database/models/player/location'
  end

  # Game-related objects, modules, and classes.
  module Game

    # Entity-related objects, models, and helpers.
    module Entity
      autoload :Context,              'game/entity/context'
      autoload :Mob,                  'game/entity/mob'
      autoload :Animation,            'game/entity/models/animation'
      autoload :Command,              'game/entity/models/command'
      autoload :Graphic,              'game/entity/models/graphic'
      autoload :ChatMessage,          'game/entity/models/chat_message'

      # Commands executable by an entity.
      module Commands
        autoload :Ascend,             'game/entity/commands/ascend'
        autoload :Animation,          'game/entity/commands/animation'
        autoload :Ban,                'game/entity/commands/ban'
        autoload :Descend,            'game/entity/commands/descend'
        autoload :Design,             'game/entity/commands/design'
        autoload :Graphic,            'game/entity/commands/graphic'
        autoload :Item,               'game/entity/commands/item'
        autoload :Morph,              'game/entity/commands/morph'
        autoload :Position,           'game/entity/commands/position'
        autoload :To,                 'game/entity/commands/to'
        autoload :Show,               'game/entity/commands/show'
      end

      # Helper functions and objects used by an entity
      module Helpers
        autoload :Command,              'game/entity/helpers/command'
        autoload :Equipment,            'game/entity/helpers/equipment'
        autoload :Flags,                'game/entity/helpers/flags'
        autoload :Inventory,            'game/entity/helpers/inventory'
        autoload :Movement,             'game/entity/helpers/movement'
      end
    end

    # Models and objects related to game items.
    module Item
      MAX_SIZE = (2**31 - 1).freeze

      autoload :Stack,                'game/item/stack'
      autoload :Container,            'game/item/container'
    end

    # Virtual Game world objects, models, and helpers.
    module World
      ACTION_PRIORITIES = { HIGH: 1, MEDIUM: 2, LOW: 3 }.freeze

      autoload :Instance,             'game/world/instance'
      autoload :Gateway,              'game/world/helpers/gateway'
      autoload :Pipeline,             'game/world/helpers/pipeline'
      autoload :Setup,                'game/world/helpers/setup'
      autoload :Synchronization,      'game/world/helpers/synchronization'
      autoload :Action,               'game/world/models/action'
    end

    # Models, functions, and objects related to coordinating and mapping the virtual game world
    module Map
      require_relative                'game/map/constants'
      include Constants

      autoload :Position,             'game/map/position'
      autoload :Direction,            'game/map/direction'
      autoload :Regional,             'game/map/regional'
    end
  end

  # Network-related objects, models, and helpers.
  module Network
    autoload :Dispatcher,           'network/dispatcher'
    autoload :Endpoint,             'network/endpoint'
    autoload :Handshake,            'network/handshake'
    autoload :ISAAC,                'network/isaac'
    autoload :Message,              'network/message'
    autoload :Parser,               'network/parser'
    autoload :Session,              'network/session'
    autoload :Constants,            'network/constants'

    # Messages compatible with the 317 protocol of RS.
    module RS317
      autoload :CenterRegionMessage,            'network/protocol/rs317/outgoing/center_region'
      autoload :ClearInterfacesMessage,         'network/protocol/rs317/outgoing/clear_interfaces'
      autoload :ContextStateBlock,              'network/protocol/rs317/outgoing/state'
      autoload :ContextSynchronizationMessage,  'network/protocol/rs317/outgoing/synchronization'
      autoload :DisplayInterfaceMessage,        'network/protocol/rs317/outgoing/interface'
      autoload :DisplaySidebarMessage,          'network/protocol/rs317/outgoing/sidebar'
      autoload :DisplayOverlayMessage,          'network/protocol/rs317/outgoing/overlay'
      autoload :LogoutMessage,                  'network/protocol/rs317/outgoing/logout'
      autoload :MembersAndIndexMessage,         'network/protocol/rs317/outgoing/membership_and_index'
      autoload :SystemTextMessage,              'network/protocol/rs317/outgoing/system_text'
      autoload :UpdateItemsMessage,             'network/protocol/rs317/outgoing/update_items'
      autoload :UpdateSlottedItemMessage,       'network/protocol/rs317/outgoing/update_slotted'
      autoload :StatUpdateMessage,              'network/protocol/rs317/outgoing/stat'

      autoload :ActionClickMessage,             'network/protocol/rs317/incoming/action'
      autoload :ArrowKeyMessage,                'network/protocol/rs317/incoming/arrow'
      autoload :ButtonClickMessage,             'network/protocol/rs317/incoming/button'
      autoload :PublicChatMessage,              'network/protocol/rs317/incoming/chat'
      autoload :MouseClickMessage,              'network/protocol/rs317/incoming/click'
      autoload :CommandMessage,                 'network/protocol/rs317/incoming/command'
      autoload :ContextDesignMessage,           'network/protocol/rs317/incoming/design'
      autoload :WindowFocusMessage,             'network/protocol/rs317/incoming/focus'
      autoload :HeartbeatMessage,               'network/protocol/rs317/incoming/heartbeat'
      autoload :MouseEventMessage,              'network/protocol/rs317/incoming/mouse'
      autoload :MovementMessage,                'network/protocol/rs317/incoming/movement'
      autoload :OptionClickMessage,             'network/protocol/rs317/incoming/option'
      autoload :PingMessage,                    'network/protocol/rs317/incoming/ping'
      autoload :SwitchItemMessage,              'network/protocol/rs317/incoming/switch'
    end

    # Messages compatible with the 377 protocol of RS.
    module RS377
      autoload :CenterRegionMessage,            'network/protocol/rs377/outgoing/center_region'
      autoload :ClearInterfacesMessage,         'network/protocol/rs377/outgoing/clear_interfaces'
      autoload :ContextSynchronizationMessage,  'network/protocol/rs377/outgoing/synchronization'
      autoload :ContextStateBlock,              'network/protocol/rs377/outgoing/state'
      autoload :DisplayInterfaceMessage,        'network/protocol/rs377/outgoing/interface'
      autoload :DisplayOverlayMessage,          'network/protocol/rs377/outgoing/overlay'
      autoload :DisplaySidebarMessage,          'network/protocol/rs377/outgoing/sidebar'
      autoload :LogoutMessage,                  'network/protocol/rs377/outgoing/logout'
      autoload :MembersAndIndexMessage,         'network/protocol/rs377/outgoing/membership_and_index'
      autoload :SystemTextMessage,              'network/protocol/rs377/outgoing/system_text'
      autoload :UpdateItemsMessage,             'network/protocol/rs377/outgoing/update_items'
      autoload :UpdateSlottedItemMessage,       'network/protocol/rs377/outgoing/update_slotted'
      autoload :StatUpdateMessage,              'network/protocol/rs377/outgoing/stat'

      autoload :ActionClickMessage,             'network/protocol/rs377/incoming/action'
      autoload :ArrowKeyMessage,                'network/protocol/rs377/incoming/arrow'
      autoload :ButtonClickMessage,             'network/protocol/rs377/incoming/button'
      autoload :PublicChatMessage,              'network/protocol/rs377/incoming/chat'
      autoload :MouseClickMessage,              'network/protocol/rs377/incoming/click'
      autoload :CommandMessage,                 'network/protocol/rs377/incoming/command'
      autoload :ContextDesignMessage,           'network/protocol/rs377/incoming/design'
      autoload :WindowFocusMessage,             'network/protocol/rs377/incoming/focus'
      autoload :HeartbeatMessage,               'network/protocol/rs377/incoming/heartbeat'
      autoload :MouseEventMessage,              'network/protocol/rs377/incoming/mouse'
      autoload :MovementMessage,                'network/protocol/rs377/incoming/movement'
      autoload :OptionClickMessage,             'network/protocol/rs377/incoming/option'
      autoload :PingMessage,                    'network/protocol/rs377/incoming/ping'
      autoload :SwitchItemMessage,              'network/protocol/rs377/incoming/switch'
    end

    include Constants
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