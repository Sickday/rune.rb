module RuneRb::Database
  class Location < Sequel::Model(PROFILES[:location])
    def position
      RuneRb::Game::Map::Position.new(self[:x], self[:y], self[:z])
    end

    def set(x, y, z)
      update(prev_x: self[:x],
             prev_y: self[:y],
             prev_z: self[:z])
      update(x: x,
             y: y,
             z: z)
    end
  end
end