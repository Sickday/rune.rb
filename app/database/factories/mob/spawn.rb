module RuneRb::Database::Factories::Mob
  class Spawn < RuneRb::Database::Mob::Spawn
    def generate(count: 1)
      count.times do
        insert()
      end
    end
  end
end
