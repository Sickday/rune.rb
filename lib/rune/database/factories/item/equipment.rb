module RuneRb::Database::Factories::Item
  class Equipment < RuneRb::Database::Item::Equipment
    def generate(count: 1)
      count.times do
        insert()
      end
    end
  end
end
