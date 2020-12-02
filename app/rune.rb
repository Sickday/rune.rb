Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }

require 'async'
require 'concurrent'
require 'console'
require 'dotenv/load'
require 'druuid'
require 'eventmachine'
require 'fileutils'
require 'oj'
require 'parallel'
require 'pastel'
require 'pry'
require 'sequel'
require 'tty-logger'

module RuneRb
  # RuneRb::Database
  module Database
    require_relative                'db/connection'

    autoload :Appearance,           'db/models/appearance'
    autoload :Equipment,            'db/models/equipment'
    autoload :Item,                 'db/models/item'
    autoload :Location,             'db/models/location'
    autoload :Profile,              'db/models/profile'
    autoload :Stats,                'db/models/stats'
    autoload :Settings,             'db/models/settings'
  end

  # This module contains objects, models, and helpers related to game entities.
  module Entity
    autoload :Context,              'game/entity/context'
    autoload :Mob,                  'game/entity/mob'
    autoload :Animation,            'game/entity/models/animation'
    autoload :Graphic,              'game/entity/models/graphic'
    autoload :Message,              'game/entity/models/message'

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

  # This module contains Internal helpers, objects, and functions.
  module Internal
    autoload :Log,                  'internal/log'
    autoload :Routine,              'internal/routine'
  end

  # This module contains objects, models, and helpers related to network activity.
  module Net
    require_relative 'network/constants'
    include Constants

    autoload :Endpoint,             'network/endpoint'
    autoload :Peer,                 'network/peer'

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

  # This module contains models, functions, and objects related to coordinating the virtual game map
  module Map
    require_relative                'map/constants'
    include Constants

    autoload :Position,             'map/position'
    autoload :Direction,            'map/direction'
    autoload :Regional,             'map/regional'
  end

  # This module contains various refinements made to objects already defined int he stdlib. These are done in the form of refinements which are used in the objects who require the functions defined in the refinement. Doing this prevents pollution of the global definitions of the objects.
  module Patches
    autoload :ArrayOverrides,       'internal/patches/array'
    autoload :IntegerOverrides,     'internal/patches/integer'
    autoload :SetOverrides,         'internal/patches/set'
    autoload :StringOverrides,      'internal/patches/string'
  end

  # This module contains objects, models, and helpers to simulate and handle a virtual game world.
  module World
    autoload :Instance,             'game/world/instance'
    autoload :Command,              'game/world/models/command'
    autoload :CommandHelper,        'game/world/helpers/command'
    autoload :LoginHelper,          'game/world/helpers/login'

    # This module contains world commands.
    module Commands
      autoload :Ascend,             'game/world/commands/ascend'
      autoload :Animation,          'game/world/commands/animation'
      autoload :Ban,                'game/world/commands/ban'
      autoload :Descend,            'game/world/commands/descend'
      autoload :Design,             'game/world/commands/design'
      autoload :Graphic,            'game/world/commands/graphic'
      autoload :Item,               'game/world/commands/item'
      autoload :Morph,              'game/world/commands/morph'
      autoload :Position,           'game/world/commands/position'
      autoload :To,                 'game/world/commands/to'
      autoload :Show,               'game/world/commands/show'
    end
  end

  # Set the logfile path.
  LOG_FILE_PATH = ENV['LOG_FILE_PATH'] || "#{FileUtils.pwd}/assets/log/rune_rb-#{Time.now.strftime('%Y-%m-%d').chomp}.log".freeze
  FileUtils.mkdir_p("#{FileUtils.pwd}/assets/log")

  # Initialize a new log file
  LOG_FILE = Logger.new(LOG_FILE_PATH, progname: ENV['TITLE'] || 'RuneRb')
  # Initialize a new logger
  LOG = TTY::Logger.new
  COL = Pastel.new
  DEBUG = ENV['DEBUG'].to_i.positive?
end