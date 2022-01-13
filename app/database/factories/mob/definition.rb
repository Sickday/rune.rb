module RuneRb::Database::Factories::Mob
  class Definition < RuneRb::Database::Mob::Definition
    def generate
      insert()
    end
  end
end