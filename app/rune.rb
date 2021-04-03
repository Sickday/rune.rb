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

Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'concurrent'
require 'druuid'
require 'fileutils'
require 'fiber'
require 'logger'
require 'oj'
require 'pastel'
require 'pry'
require 'rake'
require 'sequel'
require 'socket'

##
# RuneRb -
# # A game server written in Ruby targeting the 2006 era (or the 317-377 protocols) of the popular MMORPG, RuneScape.
#
#
# @author Patrick W.
# @since 0.9.0
module RuneRb

  # Ths module contains internally used Errors, Patches, and Modules.
  module System
    PRIORITIES = { HIGH: 2, MEDIUM: 1, LOW: 0 }.freeze
    autoload :Setup,                'system/setup'
    autoload :Log,                  'system/log'

    module Errors
      autoload :ConflictingNameError,         'system/errors'
      autoload :SessionReceptionError,        'system/errors'
    end

    # This module contains various refinements made to objects already defined int he stdlib. The refinements are used in the objects who require the functions defined in the refinement. Doing this prevents pollution of the global definitions of the stdlib objects.
    module Patches
      autoload :IntegerRefinements,     'system/patches/integer'
      autoload :SetRefinements,         'system/patches/set'
      autoload :StringRefinements,      'system/patches/string'
    end
  end

  begin
    GLOBAL = {}.tap do |data|
      RuneRb::System::Setup.load_global_data(data)
      RuneRb::System::Setup.load_logger(data)
      data[:LOG].info "RuneRb v#{data[:VERSION]} loading.."
      RuneRb::System::Setup.load_game_data(data)
      data[:LOG].info "Loaded Game database."
      RuneRb::System::Setup.load_item_data(data)
      data[:LOG].info "Loaded Item database."
      RuneRb::System::Setup.load_player_data(data)
      data[:LOG].info "Loaded Player database."
      RuneRb::System::Setup.load_mob_data(data)
      data[:LOG].info "Loaded Mob database."
    end
    GLOBAL[:LOG].info GLOBAL[:COLOR].green.bold("Completed Loading!")
  rescue StandardError => e
    puts 'An error occurred while loading Global settings!'
    puts e
    puts e.backtrace
    exit
  end

  # This module contains various database model objects which map to rows within database tables.
  module Database
    autoload :GameBannedNames,            'database/models/game/banned_names'
    autoload :GameLocation,               'database/models/game/location'
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
  end

  # This module encapsulates all Game-related objects, modules, and classes.
  module Game

    # This module contains objects, models, and helpers related to game entities.
    module Entity
      autoload :Context,              'game/entity/context'
      autoload :Mob,                  'game/entity/mob'
      autoload :Animation,            'game/entity/models/animation'
      autoload :Command,              'game/entity/models/command'
      autoload :Graphic,              'game/entity/models/graphic'
      autoload :ChatMessage,          'game/entity/models/chat_message'

      # This module contains commands executable by an entity.
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

      # This module provides helper functions and objects to an entity
      module Helpers
        autoload :Button,               'game/entity/helpers/button'
        autoload :Click,                'game/entity/helpers/click'
        autoload :Command,              'game/entity/helpers/command'
        autoload :Equipment,            'game/entity/helpers/equipment'
        autoload :Flags,                'game/entity/helpers/flags'
        autoload :Inventory,            'game/entity/helpers/inventory'
        autoload :Movement,             'game/entity/helpers/movement'
      end
    end

    # This module contains models and objects related to game items.
    module Item
      MAX_SIZE = 2**31 - 1
      autoload :Stack,                'game/item/stack'
      autoload :Container,            'game/item/container'
    end

    # This module contains objects, models, and helpers to simulate and handle a virtual game world.
    module World
      autoload :Instance,             'game/world/instance'
      autoload :Authorization,        'game/world/helpers/authorization'
      autoload :Pipeline,             'game/world/helpers/pipeline'
      autoload :Setup,                'game/world/helpers/setup'
      autoload :Task,                 'game/world/models/task'
    end

    # This module contains models, functions, and objects related to coordinating and mapping the virtual game world
    module Map
      require_relative                'game/map/constants'
      include Constants

      autoload :Position,             'game/map/position'
      autoload :Direction,            'game/map/direction'
      autoload :Regional,             'game/map/regional'
    end
  end

  # This module contains objects, models, and helpers related to network activity.
  module Network
    require_relative 'network/constants'
    include Constants

    autoload :Endpoint,             'network/endpoint'
    autoload :Dispatcher,           'network/dispatcher'
    autoload :ISAAC,                'network/isaac'
    autoload :Handshake,            'network/handshake'
    autoload :Message,              'network/message'
    autoload :Parser,               'network/parser'
    autoload :Session,              'network/session'

    # This module contains subclasses of the RuneRb::Network::Message object type.
    module Templates
      autoload :CenterRegionMessage,            'network/templates/center_region'
      autoload :ClearInterfacesMessage,         'network/templates/clear_interfaces'
      autoload :ContextInventoryMessage,        'network/templates/context_inventory'
      autoload :EquipmentSlotMessage,           'network/templates/equipment_slot'
      autoload :InterfaceMessage,               'network/templates/interface'
      autoload :LogoutMessage,                  'network/templates/logout'
      autoload :MembersAndIndexMessage,         'network/templates/membership_and_index'
      autoload :ServerTextMessage,              'network/templates/server_text'
      autoload :StatMessage,                    'network/templates/stat'
      autoload :SwitchSidebarMessage,           'network/templates/switch_sidebar'
      autoload :OverlayMessage,                 'network/templates/overlay'
      autoload :SynchronizationMessage,         'network/templates/synchronization'
      autoload :StateBlockMessage,              'network/templates/state'
    end
  end
end
