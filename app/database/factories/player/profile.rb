module RuneRb::Database::Factories::Player
  class Profile < RuneRb::Database::Player::Profile
    def generate(count: 1)
      count.times do
        insert(

        )
      end
    end
  end
end