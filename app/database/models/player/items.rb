module RuneRb::Database
  class PlayerItems < Sequel::Model(RuneRb::GLOBAL[:DATABASE].player[:player_items]); end
end
