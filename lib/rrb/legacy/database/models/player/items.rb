module RuneRb::Database
  class PlayerItems < Sequel::Model(RuneRb::GLOBAL_DATABASE.player[:player_items]); end
end
