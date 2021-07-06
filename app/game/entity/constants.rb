module RuneRb::Game::Entity::Constants

	# @!attribute [r] MAXIMUM_EXPERIENCE
	# @return [Integer] the maximum amount of experience that can be gained.
	MAXIMUM_EXPERIENCE = 200_000_000

	# @return [Hash] a map of skills and their level and exp column labels.
	SKILLS = {
		ATTACK: %i[attack_level attack_exp],
		DEFENCE: %i[defence_level defence_exp],
		STRENGTH: %i[strength_level strength_exp],
		HIT_POINTS: %i[hit_points_level hit_points_exp],
		RANGE: %i[range_level range_exp],
		PRAYER: %i[prayer_level prayer_exp],
		MAGIC: %i[magic_level magic_exp],
		COOKING: %i[cooking_level cooking_exp],
		WOODCUTTING: %i[woodcutting_level woodcutting_exp],
		FLETCHING: %i[fletching_level fletching_exp],
		FISHING: %i[fishing_level fishing_exp],
		FIREMAKING: %i[firemaking_level firemaking_exp],
		CRAFTING: %i[crafting_level crafting_exp],
		SMITHING: %i[smithing_level smithing_exp],
		MINING: %i[mining_level mining_exp],
		HERBLORE: %i[herblore_level herblore_exp],
		AGILITY: %i[agility_level agility_exp],
		THIEVING: %i[thieving_level thieving_exp],
		SLAYER: %i[slayer_level slayer_exp],
		FARMING: %i[farming_level farming_exp],
		RUNECRAFTING: %i[runecrafting_level runecrafting_exp]
	}.freeze

	ACTION_PRIORITIES = { WEAK: 1, NORMAL: 2, STRONG: 3 }.freeze
end