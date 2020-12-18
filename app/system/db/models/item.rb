module RuneRb::System::Database
  class Item < Sequel::Model(RuneRb::ITEM_DEFINITIONS)
    plugin :static_cache

    def high_alch
      (0.6 * self[:value]).to_i
    end

    def low_alch
      (0.4 * self[:value]).to_i
    end
  end
end