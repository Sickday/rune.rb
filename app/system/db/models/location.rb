module RuneRb::System::Database
  class Location < Sequel::Model(RuneRb::PLAYER_LOCATIONS)
    def to_position
      RuneRb::Game::Map::Position.new(self[:x], self[:y], self[:z])
    end

    def set(position)
      update(prev_x: self[:x],
             prev_y: self[:y],
             prev_z: self[:z],
             x: position[:x] || RuneRb::GLOBAL[:DEFAULT_MOB_X] || 3222,
             y: position[:y] || RuneRb::GLOBAL[:DEFAULT_MOB_Y] || 3222,
             z: position[:z] || RuneRb::GLOBAL[:DEFAULT_MOB_Z] || 0)
    end
  end
end