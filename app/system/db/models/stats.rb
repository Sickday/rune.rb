module RuneRb::System::Database
  # The Stats object models the public.stats table rows which relate to a player's stats.
  class Stats < Sequel::Model(RuneRb::PLAYER_STATS)
    attr :level_up

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

    LevelUpInfo = Struct.new(:skill, :level)

    # Calculates the combat level
    def combat
      combat = ((self[:defence_level] + self[:hit_points_level] + (self[:prayer_level] / 2).floor) * 0.2535).to_i + 1
      melee = (self[:attack_level] + self[:strength_level]) * 0.325
      ranger = (self[:range_level] * 1.5).to_i.floor * 0.325
      magic = (self[:magic_level] * 1.5).to_i.floor * 0.325

      combat += melee if melee >= ranger && melee >= magic
      combat += ranger if ranger >= melee && ranger >= magic
      combat += magic if magic >= melee && magic >= ranger
      combat <= 126 ? combat : 126
    end

    # Calculates the total level of all stat levels added.
    def total
      self[:attack_level] + self[:defence_level] + self[:strength_level] + self[:hit_points_level] +
        self[:range_level] + self[:prayer_level] + self[:magic_level] + self[:cooking_level] +
        self[:woodcutting_level] + self[:fletching_level] + self[:fishing_level] + self[:firemaking_level] +
        self[:crafting_level] + self[:smithing_level] + self[:mining_level] + self[:herblore_level] +
        self[:agility_level] + self[:thieving_level] + self[:slayer_level] + self[:farming_level] + self[:runecrafting_level]
    end

    # Updates a skill's level to that of the passed parameter
    # @param skill [Symbol] the skill to update
    # @param to [Integer] the level to update to
    def update_level(skill, to)
      @level_up = LevelUpInfo.new(skill, to) if self[SKILLS[skill].first] > to
      update(SKILLS[skill].first => to)
    end

    # Updates a skill's experience to that of the passed parameter
    # @param skill [Symbol] the skill to update
    # @param to [Integer] the experience to update to
    def update_exp(skill, to)
      if to >= MAXIMUM_EXPERIENCE
        update(SKILLS[skill].last => MAXIMUM_EXPERIENCE)
      else
        update(SKILLS[skill].last => to)
        normalize(skill)
      end
    end

    # Attempts to normalize the level of the skill
    # @param skill [Symbol] the skill to normalize
    def normalize(skill)
      update_level(skill, RuneRb::System::Database::Stats.level_for_experience(self[SKILLS[skill].last]))
    end

    def add_experience(skill, amount)
      eventual = self[SKILLS[skill].last] + amount
      update_exp(skill, eventual)
    end

    # Updates all skills to 99.
    def max
      SKILLS.each do |_label, columns|
        update(columns.first => 99)
        update(columns.last => 13_034_430)
      end
    end

    # @return [Boolean] is a level up required?
    def level_up?
      true unless @level_up.nil?
    end

    class << self
      # Calculates the appropriate level for the amount of passed experience
      # @param xp [Intger] the experience to fetch the level for.
      # @return [Integer] the skill level for the given amount of experience
      def level_for_experience(xp)
        if xp > 13_034_430
          99
        else
          points = 0
          lvl = (1..99).detect do |level|
            points += (level + 300.0 * (2**(level / 7.0))).floor
            (points / 4).floor >= xp
          end
          lvl >= 99 ? 99 : lvl
        end
      end
    end
  end
end