require "rsrs/version"
require 'sequel'
require 'pry'
require 'sorbet-runtime'

module RSRS
  autoload :World,   'rsrs/game/world'
  autoload :DatabaseManager,  'rsrs/db/manager'

  module API
    autoload :AssetManager, 'rsrs/api/asset_manager'
  end
  module Models
    autoload :Item,   'rsrs/db/model/item'
    autoload :NPC,    'rsrs/db/model/npc'
  end
end
