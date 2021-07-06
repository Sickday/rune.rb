module RuneRb
	module Game

		# Entity-related objects, models, and helpers.
		module Entity
			autoload :Context,              'game/entity/context'
			autoload :Constants,						'game/entity/constants'
			autoload :Mob,                  'game/entity/mob'
			autoload :Animation,            'game/entity/models/animation'
			autoload :Command,              'game/entity/models/command'
			autoload :Graphic,              'game/entity/models/graphic'
			autoload :ChatMessage,          'game/entity/models/chat_message'

			# Commands executable by an entity.
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

			# Helper functions and objects used by an entity
			module Helpers
				autoload :Command,              'game/entity/helpers/command'
				autoload :Equipment,            'game/entity/helpers/equipment'
				autoload :Flags,                'game/entity/helpers/flags'
				autoload :Inventory,            'game/entity/helpers/inventory'
				autoload :Movement,             'game/entity/helpers/movement'
				autoload :Status,               'game/entity/helpers/status'
				autoload :Stats,                'game/entity/helpers/stats'
				autoload :Queue,                'game/entity/helpers/queue'
			end

			include Constants
		end

		# Models and objects related to game items.
		module Item
			MAX_SIZE = (2**31 - 1).freeze

			autoload :Stack,                'game/item/stack'
			autoload :Container,            'game/item/container'
		end

		# Virtual Game world objects, models, and helpers.
		module World
			autoload :Instance,             'game/world/instance'
			autoload :Constants,						'game/world/constants'
			autoload :Gateway,              'game/world/helpers/gateway'
			autoload :Pipeline,             'game/world/helpers/pipeline'
			autoload :Setup,                'game/world/helpers/setup'
			autoload :Synchronization,      'game/world/helpers/synchronization'
			autoload :Task,                 'game/world/models/task'

			include Constants
		end

		# Models, functions, and objects related to coordinating and mapping the virtual game world
		module Map
			autoload :Constants,						'game/map/constants'
			autoload :Position,             'game/map/position'
			autoload :Direction,            'game/map/direction'
			autoload :Regional,             'game/map/regional'

			include Constants
		end
	end
end