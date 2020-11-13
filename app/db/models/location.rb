module RuneRb::Database
  class Location < Sequel::Model(PROFILES[:location])
    def position
      RuneRb::Game::Map::Position.new(self[:x], self[:y], self[:z])
    end

    def set(x, y, z)
      update(prev_x: self[:x],
             prev_y: self[:y],
             prev_z: self[:z],
             x: x || ENV['DEFAULT_X'] || 3222,
             y: y || ENV['DEFAULT_Y'] || 3222,
             z: z || ENV['DEFAULT_Z'] || 0)
    end
  end
end