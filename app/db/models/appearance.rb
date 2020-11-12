module RuneRb::Database
  class Appearance < Sequel::Model(PROFILES[:appearance])
    def to_mob(id)
      update(mob_id: id)
    end

    def from_mob
      update(mob_id: -1)
    end
  end
end