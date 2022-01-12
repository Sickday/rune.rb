module RuneRb::Database
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