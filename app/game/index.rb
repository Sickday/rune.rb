# frozen_string_literal: true

Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

# Game-related objects, modules, and classes.
module RuneRb::Game

  # Entity-related objects, models, and helpers.
  module Entity
    autoload :Context,              'entity/context'
    autoload :Mob,                  'entity/mob'
    autoload :Animation,            'entity/models/animation'
    autoload :Command,              'entity/models/command'
    autoload :Graphic,              'entity/models/graphic'
    autoload :ChatMessage,          'entity/models/chat_message'

    # Commands executable by an entity.
    module Commands
      autoload :Ascend,             'entity/commands/ascend'
      autoload :Animation,          'entity/commands/animation'
      autoload :Ban,                'entity/commands/ban'
      autoload :Descend,            'entity/commands/descend'
      autoload :Design,             'entity/commands/design'
      autoload :Graphic,            'entity/commands/graphic'
      autoload :Item,               'entity/commands/item'
      autoload :Morph,              'entity/commands/morph'
      autoload :Position,           'entity/commands/position'
      autoload :To,                 'entity/commands/to'
      autoload :Show,               'entity/commands/show'
    end

    # Helper functions and objects used by an entity
    module Helpers
      autoload :Command,              'entity/helpers/command'
      autoload :Equipment,            'entity/helpers/equipment'
      autoload :Flags,                'entity/helpers/flags'
      autoload :Inventory,            'entity/helpers/inventory'
      autoload :Movement,             'entity/helpers/movement'
    end
  end

  # Models and objects related to game items.
  module Item
    MAX_SIZE = (2**31 - 1)

    autoload :Stack,                'item/stack'
    autoload :Container,            'item/container'
  end

  # Virtual Game world objects, models, and helpers.
  module World
    ACTION_PRIORITIES = { HIGH: 1, MEDIUM: 2, LOW: 3 }.freeze

    autoload :Instance,             'world/instance'
    autoload :Gateway,              'world/helpers/gateway'
    autoload :Pipeline,             'world/helpers/pipeline'
    autoload :Synchronization,      'world/helpers/synchronization'
    autoload :Action,               'world/models/action'
  end

  # Models, functions, and objects related to coordinating and mapping the virtual game world
  module Map
    autoload :Constants,            'map/constants'
    autoload :Position,             'map/position'
    autoload :Direction,            'map/direction'
    autoload :Regional,             'map/regional'

    include Constants
  end
end
