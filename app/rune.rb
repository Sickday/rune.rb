Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }

require 'async'
require 'async/io/tcp_socket'
require 'async/container'
require 'console'
require 'druuid'
require 'fileutils'
require 'logger'
require 'nio'
require 'oj'
require 'pastel'
require 'pry'
require 'sequel'
require 'timers'

require_relative 'system/setup'

module RuneRb
  # Including this file will define it's constants in the RuneRb namespace, making them available to it's children.
  include Setup

  module Game
    # This module contains objects, models, and helpers related to game entities.
    module Entity
      autoload :Context,              'game/entity/context'
      autoload :Mob,                  'game/entity/mob'
      autoload :Animation,            'game/entity/models/animation'
      autoload :Command,              'game/entity/models/command'
      autoload :Graphic,              'game/entity/models/graphic'
      autoload :Message,              'game/entity/models/message'

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
      autoload :LoginHelper,          'game/world/helpers/login'
      autoload :Scheduler,            'game/world/helpers/container'
    end

    # This module contains models, functions, and objects related to coordinating the virtual game map
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
    require_relative                'network/constants'
    include Constants

    autoload :Endpoint,             'network/endpoint'
    autoload :Session,              'network/session'
    autoload :ISAAC,                'network/isaac'
    autoload :LoginHelper,          'network/helpers/login'
    autoload :Frame,                'network/frame'
    autoload :MetaFrame,            'network/frame/meta'
    autoload :StaticFrame,          'network/frame/static'
    autoload :FrameReader,          'network/helpers/reader'
    autoload :FrameWriter,          'network/helpers/writer'

    # This module contains meta frames that will always be parsed the same way
    module Meta
      autoload :ClearInterfacesFrame,  'network/frame/meta/clear_interfaces'
      autoload :OverlayInterfaceFrame, 'network/frame/meta/overlay'
      autoload :InterfaceFrame,        'network/frame/meta/interface'
      autoload :CloseConnectionFrame, 'network/frame/meta/close_connection'
      autoload :CenterRegionFrame, 'network/frame/meta/region'
      autoload :ContextInventoryFrame, 'network/frame/meta/inventory'
      autoload :SystemMessageFrame, 'network/frame/meta/system_message'
      autoload :EquipmentSlotFrame, 'network/frame/meta/equipment'
      autoload :SwitchSidebarFrame, 'network/frame/meta/sidebar'
      autoload :SkillSlotFrame, 'network/frame/meta/skill'
      autoload :SynchronizationFrame, 'network/frame/meta/synchronization'
      autoload :StateBlock,           'network/frame/meta/state'
    end
  end

  module System
    autoload :Controller,           'system/controller'
    autoload :Log,                  'system/log'
    autoload :Routine,              'system/routine'
    autoload :Utils,                'system/utils'

    # RuneRb::System::Database
    module Database
      autoload :Appearance,           'system/db/models/appearance'
      autoload :Equipment,            'system/db/models/equipment'
      autoload :Item,                 'system/db/models/item'
      autoload :Location,             'system/db/models/location'
      autoload :Profile,              'system/db/models/profile'
      autoload :Stats,                'system/db/models/stats'
      autoload :Settings,             'system/db/models/settings'
      autoload :BannedNames,          'system/db/models/system'
      autoload :Snapshots,            'system/db/models/system'
    end

    # This module contains various refinements made to objects already defined int he stdlib. These are done in the form of refinements which are used in the objects who require the functions defined in the refinement. Doing this prevents pollution of the global definitions of the objects.
    module Patches
      autoload :ArrayOverrides,       'system/patches/array'
      autoload :IntegerOverrides,     'system/patches/integer'
      autoload :SetOverrides,         'system/patches/set'
      autoload :StringOverrides,      'system/patches/string'
    end
  end

end