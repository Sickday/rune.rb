# frozen_string_literal: true

Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }

module RuneRb::Database

  # Factory objects to generate fake data using models.
  module Factories
    autoload :PlayerProfile,     'factories/player/profile'

    autoload :ItemDefinition,    'factories/item/definition'
    autoload :ItemEquipment,     'factories/item/equipment'
    autoload :ItemSpawn,         'factories/item/spawn'

    autoload :MobDefinition,     'factories/mob/definition'
    autoload :MobSpawn,          'factories/mob/spawn'
  end

  autoload :PlayerAppearance,    'models/player/appearance'
  autoload :PlayerItems,         'models/player/items'
  autoload :PlayerAttributes,    'models/player/attributes'
  autoload :PlayerLocation,      'models/player/location'
  autoload :PlayerProfile,       'models/player/profile'
  autoload :PlayerSettings,      'models/player/settings'
  autoload :PlayerSkills,        'models/player/skills'

  autoload :ItemDefinition,      'models/item/definition'
  autoload :ItemEquipment,       'models/item/equipment'
  autoload :ItemSpawn,           'models/item/spawn'

  autoload :MobAnimations,       'models/mob/animations'
  autoload :MobDefinition,       'models/mob/definition'
  autoload :MobSpawn,            'models/mob/spawn'
  autoload :MobStats,            'models/mob/stats'

  autoload :SystemBannedNames,   'models/system/banned_names'
  autoload :SystemSnapshots,     'models/system/snapshot'
end
