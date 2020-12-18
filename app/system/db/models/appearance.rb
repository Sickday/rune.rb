module RuneRb::System::Database
  class Appearance < Sequel::Model(RuneRb::PLAYER_APPEARANCES)
    def to_mob(id)
      update(mob_id: id)
    end

    def from_mob
      update(mob_id: -1)
    end

    def to_head(id)
      update(head_icon: id)
    end

    # Reads and parses an appearance from a frame.
    # @param frame [RuneRb::Network::Frame] the frame to read from
    def from_frame(frame)
      update(gender: frame.read_byte,
             head: frame.read_byte,
             beard: frame.read_byte,
             chest: frame.read_byte,
             arms: frame.read_byte,
             hands: frame.read_byte,
             legs: frame.read_byte,
             feet: frame.read_byte,
             hair_color: frame.read_byte,
             torso_color: frame.read_byte,
             leg_color: frame.read_byte,
             feet_color: frame.read_byte,
             skin_color: frame.read_byte)
    end
  end
end