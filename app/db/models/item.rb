module RuneRb::Database
  class Item < Sequel::Model(DEFINITIONS[:item_definitions])
    plugin :static_cache
    def highalc
      (0.6 * Sequel[:basevalue]).to_i
    end

    def lowalc
      (0.4 * Sequel[:basevalue]).to_i
    end
  end
end