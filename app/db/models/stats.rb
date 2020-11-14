module RuneRb::Database
  class Stats < Sequel::Model(PROFILES[:stats])
    MAXIMUM_EXPERIENCE = 200_000_000

    SKILLS = {
      ATTACK: %i[attack_level attack_experience],
      DEFENCE: %i[defence_level defence_experience],
      STRENGTH: %i[strength_level strength_experience],
      HIT_POINTS: %i[hit_points_level hit_points_experience],
      RANGE: %i[range_level range_experience],
      PRAYER: %i[prayer_level prayer_experience],
      MAGIC: %i[magic_level magic_experience],
      COOKING: %i[cooking_level cooking_experience],
      WOODCUTTING: %i[woodcutting_level woodcutting_experience],
      FLETCHING: %i[fletching_level fletching_experience],
      FISHING: %i[fishing_level fishing_experience],
      FIREMAKING: %i[firemaking_level firemaking_experience],
      CRAFTING: %i[crafting_level crafting_experience],
      SMITHING: %i[smithing_level smithing_experience],
      MINING: %i[mining_level mining_experience],
      HERBLORE: %i[herblore_level herblore_experience],
      AGILITY: %i[agility_level agility_experience],
      THIEVING: %i[thieving_level thieving_experience],
      SLAYER: %i[slayer_level slayer_experience],
      FARMING: %i[farming_level farming_experience],
      RUNECRAFTING: %i[runecrafting_level runecrafting_experience]
    }.freeze

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

    def total
      self[:attack_level] + self[:defence_level] + self[:strength_level] + self[:hit_points_level] +
        self[:range_level] + self[:prayer_level] + self[:magic_level] + self[:cooking_level] +
        self[:woodcutting_level] + self[:fletching_level] + self[:fishing_level] + self[:firemaking_level] +
        self[:crafting_level] + self[:smithing_level] + self[:mining_level] + self[:herblore_level] +
        self[:agility_level] + self[:thieving_level] + self[:slayer_level] + self[:farming_level] +
        self[:runecrafting_level]
    end

    def set_level(skill_level, level)
      update(skill_level => level)
    end

    def set_experience(skill_experience, experience)
      update(skill_experience => experience)
    end

    def add_experience(skill_experience, amount)
      new_xp = self[skill_experience] + amount
      if new_xp > MAXIMUM_EXPERIENCE
        set_experience(skill_experience, MAXIMUM_EXPERIENCE)
      else
        set_experience(skill_experience, new_xp)
      end

      new_level = Stats.lvl_for_xp(new_xp)

    end

    class << self
      def xp_for_lvl(level)
        points = 0
        out = 0
        final = 0
        level.times do
          points += (final + 300.0 * (2.0**(final / 7.0))).floor
          return out if final > level

          out = (points / 4).floor
          final += 1
        end
        0
      end

      def lvl_for_xp(xp)
        points = 0
        level = 1
        99.times do
          points += (level * 300.0 * (2.0**(level / 7.0))).floor
          out = (points / 4).floor
          return level if out > xp

          level += 1
        end
        99
      end
    end
  end
end