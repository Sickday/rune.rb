# frozen_string_literal: true

Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }

module RuneRb::Database

  # Factory objects to generate fake data using models.
  module Factories

    module Player
      autoload :Profile,     'factories/player/profile'
    end

    module Item
      autoload :Definition,  'factories/item/definition'
      autoload :Equipment,   'factories/item/equipment'
      autoload :Spawn,       'factories/item/spawn'
    end

    module Mob
      autoload :Definition,  'factories/mob/definition'
      autoload :Spawn,       'factories/mob/spawn'
    end

    module System
      autoload :Location,    'factories/system/location'
    end
  end

  module Player
    autoload :Appearance,    'models/player/appearance'
    autoload :Attributes,    'models/player/attributes'
    autoload :Location,      'models/player/location'
    autoload :Profile,       'models/player/profile'
    autoload :Settings,      'models/player/settings'
    autoload :Skills,        'models/player/skills'
  end

  module Item
    autoload :Definition,    'models/item/definition'
    autoload :Equipment,     'models/item/equipment'
    autoload :Spawn,         'models/item/spawn'
  end

  module Mob
    autoload :Animations,    'models/mob/animations'
    autoload :Definition,    'models/mob/definition'
    autoload :Spawn,         'models/mob/spawn'
    autoload :Stats,         'models/mob/stats'
  end

  module System
    autoload :BannedNames,   'models/system/banned_names'
    autoload :Snapshots,     'models/system/snapshot'
  end
end
