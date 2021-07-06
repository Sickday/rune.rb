module RuneRb::Game::Entity::Helpers::Stats

	# @!attribute[r] level_up
	# @return [Struct, Nil] a container for the level up data.
	attr :level_up

	# Object representing a pending level increase in a specific stat
	# @param skill [Symbol] the skill which has increased in level
	# @param level [Integer] the new level of the skill
	LevelUp = Struct.new(:skill, :level)

	# Calculates the virtual combat level with the dataset's combat stats.
	#
	# @return [Integer] the calculated combat level
	def combat
		combat = ((@stats[:defence_level] + @stats[:hit_points_level] + (@stats[:prayer_level] / 2).floor) * 0.2535).to_i + 1
		melee = (@stats[:attack_level] + @stats[:strength_level]) * 0.325
		ranger = (@stats[:range_level] * 1.5).to_i.floor * 0.325
		magic = (@stats[:magic_level] * 1.5).to_i.floor * 0.325

		combat += melee if melee >= ranger && melee >= magic
		combat += ranger if ranger >= melee && ranger >= magic
		combat += magic if magic >= melee && magic >= ranger
		combat <= 126 ? combat : 126
	end

	# Calculates the total level of all stat levels added.
	# @return [Integer] the sum of all levels added.
	def total
		@stats[:attack_level] + @stats[:defence_level] + @stats[:strength_level] + @stats[:hit_points_level] +
			@stats[:range_level] + @stats[:prayer_level] + @stats[:magic_level] + @stats[:cooking_level] +
			@stats[:woodcutting_level] + @stats[:fletching_level] + @stats[:fishing_level] + @stats[:firemaking_level] +
			@stats[:crafting_level] + @stats[:smithing_level] + @stats[:mining_level] + @stats[:herblore_level] +
			@stats[:agility_level] + @stats[:thieving_level] + @stats[:slayer_level] + @stats[:farming_level] + @stats[:runecrafting_level]
	end

	# Is a level up pending?
	# @return [Boolean] is a level up required?
	def level_up?
		!@level_up.nil?
	end

	# Initializes Stats for the Context.
	def load_stats
		@stats = @profile.stats
		update(:stats)
	end

	private

	# Updates a skill's level to that of the passed parameter
	# @param skill [Symbol] the skill to update
	# @param to [Integer] the level to update to
	def update_level(skill, to)
		@level_up = LevelUp.new(skill, to) if @stats[RuneRb::Game::Entity::SKILLS[skill].first] > to
		update(RuneRb::Game::Entity::SKILLS[skill].first => to)
	end

	# Updates a skill's experience to that of the passed parameter
	# @param skill [Symbol] the skill to update
	# @param to [Integer] the experience to update to
	def update_exp(skill, to)
		if to >= MAXIMUM_EXPERIENCE
			update(RuneRb::Game::Entity::SKILLS[skill].last => RuneRb::Game::Entity::MAXIMUM_EXPERIENCE)
		else
			update(RuneRb::Game::Entity::SKILLS[skill].last => to)
			normalize(skill)
		end
	end

	# Attempts to normalize the level of the skill
	# @param skill [Symbol] the skill to normalize
	def normalize(skill)
		update_level(skill, RuneRb::Database::Player::Stats.level_for_experience(@stats[RuneRb::Game::Entity::SKILLS[skill].last]))
	end
end