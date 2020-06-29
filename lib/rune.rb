require 'logging'
require 'eventmachine'
require 'sqlite3'
require 'rufus/scheduler'
require 'ostruct'

module RuneRb
  autoload :Server, 'runerb/server'

  module Engine
    autoload :EventManager, 'runerb/core/engine'
    autoload :Event, 'runerb/core/engine'
    autoload :QueuePolicy, 'runerb/core/engine'
    autoload :WalkablePolicy, 'runerb/core/engine'
    autoload :Action, 'runerb/core/engine' # TODO move to Actions
    autoload :ActionQueue, 'runerb/core/engine' # TODO move to Actions
  end

  module Misc
    autoload :AutoHash, 'runerb/core/util'
    autoload :HashWrapper, 'runerb/core/util'
    autoload :Flags, 'runerb/core/util'
    autoload :TextUtils, 'runerb/core/util'
    autoload :NameUtils, 'runerb/core/util'
    autoload :ThreadPool, 'runerb/core/util'
    autoload :Cache, 'runerb/core/cache'
  end

  module Actions
    autoload :HarvestingAction, 'runerb/core/actions'
  end

  module Model
    autoload :HitType, 'runerb/model/combat'
    autoload :Hit, 'runerb/model/combat'
    autoload :Damage, 'runerb/model/combat'
    autoload :Animation, 'runerb/model/effects'
    autoload :Graphic, 'runerb/model/effects'
    autoload :ChatMessage, 'runerb/model/effects'
    autoload :Entity, 'runerb/model/entity'
    autoload :Location, 'runerb/model/location'
    autoload :Player, 'runerb/model/player'
    autoload :RegionManager, 'runerb/model/region'
    autoload :Region, 'runerb/model/region'
  end

  module Item
    autoload :Item, 'runerb/model/item'
    autoload :ItemDefinition, 'runerb/model/item'
    autoload :Container, 'runerb/model/item'
    autoload :ContainerListener, 'runerb/model/item'
    autoload :InterfaceContainerListener, 'runerb/model/item'
    autoload :WeightListener, 'runerb/model/item'
    autoload :BonusListener, 'runerb/model/item'
  end

  module NPC
    autoload :NPC, 'runerb/model/npc'
    autoload :NPCDefinition, 'runerb/model/npc'
  end

  module Player
    autoload :Appearance, 'runerb/model/player/appearance'
    autoload :InterfaceState, 'runerb/model/player/interfacestate'
    autoload :RequestManager, 'runerb/model/player/requestmanager'
    autoload :Skills, 'runerb/model/player/skills'
  end

  module Net
    autoload :ActionSender, 'runerb/net/actionsender'
    autoload :ISAAC, 'runerb/net/isaac'
    autoload :Session, 'runerb/net/session'
    autoload :Connection, 'runerb/net/connection'
    autoload :Packet, 'runerb/net/packet'
    autoload :PacketBuilder, 'runerb/net/packetbuilder'
    autoload :JaggrabConnection, 'runerb/net/jaggrab'
  end

  module GroundItems
    autoload :GroundItem, 'runerb/services/ground_items'
    autoload :GroundItemEvent, 'runerb/services/ground_items'
    autoload :PickupItemAction, 'runerb/services/ground_items'
  end

  module Shops
    autoload :ShopManager, 'runerb/services/shops'
    autoload :Shop, 'runerb/services/shops'
  end

  module Objects
    autoload :ObjectManager, 'runerb/services/objects'
  end

  module Doors
    autoload :DoorManager, 'runerb/services/doors'
    autoload :Door, 'runerb/services/doors'
    autoload :DoubleDoor, 'runerb/services/doors'
    autoload :DoorEvent, 'runerb/services/doors'
  end

  module Tasks
    autoload :NPCTickTask, 'runerb/tasks/npc_update'
    autoload :NPCResetTask, 'runerb/tasks/npc_update'
    autoload :NPCUpdateTask, 'runerb/tasks/npc_update'
    autoload :PlayerTickTask, 'runerb/tasks/player_update'
    autoload :PlayerResetTask, 'runerb/tasks/player_update'
    autoload :PlayerUpdateTask, 'runerb/tasks/player_update'
    autoload :SystemUpdateEvent, 'runerb/tasks/sysupdate_event'
    autoload :UpdateEvent, 'runerb/tasks/update_event'
  end

  module World
    autoload :Profile, 'runerb/world/profile'
    autoload :Pathfinder, 'runerb/world/walking'
    autoload :Point, 'runerb/world/walking'
    autoload :World, 'runerb/world/world'
    autoload :LoginResult, 'runerb/world/world'
    autoload :Loader, 'runerb/world/world'
    autoload :YAMLFileLoader, 'runerb/world/world'
    autoload :NPCSpawns, 'runerb/world/npc_spawns'
    autoload :ItemSpawns, 'runerb/world/item_spawns'
  end
end

require 'runerb/plugin_hooks'
require 'runerb/net/packetloader'

