# Author: Patrick W.
# MDate: 10/05/2020

Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }

require 'console'
require 'concurrent'
require 'dotenv/load'
require 'druuid'
require 'fileutils'
require 'logger'
require 'nio'
require 'oj'
require 'parallel'
require 'pastel'
require 'pry'
require 'psych'
require 'singleton'
require 'sequel'
require 'socket'
require 'set'


# RuneRb scratch rewrite
module RuneRb

  # RuneRb::Game
  module Game
    autoload :World,                'game/world'
    autoload :Entity,               'game/models/entity'
    autoload :ContextPlayer,        'game/models/player'
    autoload :UpdateFlags,          'game/models/flags'
    autoload :ItemStack,            'game/models/item'
    autoload :ItemContainer,        'game/models/container'
    autoload :Inventory,            'game/containers/inventory'
    autoload :Mob,                  'game/models/mob'

    # RuneRb::Game::Flags
    module Flags
      autoload :MovementFlags,      'game/flags/movement'
      autoload :StateFlags,         'game/flags/state'
    end

    # RuneRb::Game::Map
    module Map
      X_DELTAS = [-1, 0, 1, -1, 1, -1, 0, 1].freeze
      Y_DELTAS = [1, 1, 1, 0, 0, -1, -1, -1].freeze

      autoload :Movement,           'game/map/move'
      autoload :Position,           'game/map/position'
    end

    # RuneRb::Game::Services
    module Services
      autoload :MapService,         'game/services/map'
      autoload :UpdateService,      'game/services/update'
    end
  end

  # RuneRb::Entity
  module Entity
    autoload :Context,              'game/entity/context'
    autoload :Mob,                  'game/entity/mob'
    autoload :Type,                 'game/entity/type'
    autoload :Inventory,            'game/entity/containers/inventory'

    # RuneRb::Entity::Flags
    module Flags
      autoload :MovementFlags,      'game/entity/flags/movement'
      autoload :StateFlags,         'game/entity/flags/state'
    end
  end

  # RuneRb::Network
  module Network
    require_relative 'network/constants'
    include Constants

    autoload :AuthenticationHelper, 'network/login'
    autoload :Peer,                 'network/peer'
    autoload :Endpoint,             'network/endpoint'

    autoload :Frame,                'network/frame'
    autoload :MetaFrame,            'network/frame'
    autoload :InFrame,              'network/frame'
    autoload :FrameReader,          'network/frame/reader'
    autoload :FrameWriter,          'network/frame/writer'
    autoload :ISAAC,                'network/isaac'
  end

  ###
  # INTERNALS
  ###
  # RuneRb::Types
  module Types
    autoload :Loggable,             'internal/types/loggable'
    autoload :OperationChain,       'internal/types/chain'
    autoload :Routine,              'internal/types/routine'
    autoload :Serializable,         'internal/types/serializable'
    autoload :Service,              'internal/types/service'
  end

  ###
  # INTERNALS
  ###
  # RuneRb::Patches
  module Patches
    autoload :SetOverride,          'internal/patches/set'
    autoload :StringOverrides,      'internal/patches/string'
    autoload :IntegerOverrides,     'internal/patches/integer'
  end

  module Errors
    autoload :LoginError,           'internal/errors/login'
  end

  # RuneRb::Database
  module Database
    autoload :SYSTEMS,              'db/connection'
    autoload :DEFINITIONS,          'db/connection'
    autoload :PROFILES,             'db/connection'
    autoload :Appearance,           'db/models/appearance'
    autoload :Equipment,            'db/models/equipment'
    autoload :Item,                 'db/models/item'
    autoload :Location,             'db/models/location'
    autoload :Profile,              'db/models/profile'
    autoload :Stats,                'db/models/stats'
    autoload :Settings,             'db/models/settings'
  end

  # Set the logfile path.
  LOG_FILE_PATH = ENV['LOG_FILE_PATH'] || "#{FileUtils.pwd}/assets/log/rune_rb-#{Time.now.strftime('%Y-%m-%d').chomp}.log".freeze
  FileUtils.mkdir_p("#{FileUtils.pwd}/assets/log")

  # Initialize a new log file
  LOG_FILE = Logger.new(LOG_FILE_PATH, progname: ENV['TITLE'] || 'RuneRb')
  # Initialize a new logger
  LOG = Console.logger
  COL = Pastel.new

  # Debug logging
  DEBUG = ENV['DEBUG'].to_i.positive?
end