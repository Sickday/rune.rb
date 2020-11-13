module RuneRb::Database
  class Location < Sequel::Model(PROFILES[:location])
    def position
      RuneRb::Game::Map::Position.new(self[:x], self[:y], self[:z])
    end

    def set(position)
      update(prev_x: self[:x],
             prev_y: self[:y],
             prev_z: self[:z],
             x: position[:x] || ENV['DEFAULT_X'] || 3222,
             y: position[:y] || ENV['DEFAULT_Y'] || 3222,
             z: position[:z] || ENV['DEFAULT_Z'] || 0)
    end
  end
end