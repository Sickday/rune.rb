module RuneRb::Database::Factories::Item
  class Definition < RuneRb::Database::Item::Definition
    def generate(count: 1)
      count.times do
        insert(

        )
      end
    end
  end
end
