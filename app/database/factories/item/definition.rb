module RuneRb::Database::Factories::Item
  class Definition < RuneRb::Database::ItemDefinition
    def generate(count: 1)
      count.times do |it|
        insert(id: it,


        )
      end
    end
  end
end
