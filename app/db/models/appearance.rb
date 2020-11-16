module RuneRb::Database
  class Appearance < Sequel::Model(PROFILES[:appearance])
    def to_mob(id)
      update(mob_id: id)
    end

    def from_mob
      update(mob_id: -1)
    end

    def head_to(id)
      update(head_icon: id)
    end

    # Reads and parses an appearance from a frame.
    # @param frame [RuneRb::Network::InFrame] the frame to read from
    def from_frame(frame)
      update(gender: frame.read_byte(false),
             head: frame.read_byte(false),
             beard: frame.read_byte(false),
             chest: frame.read_byte(false),
             arms: frame.read_byte(false),
             hands: frame.read_byte(false),
             legs: frame.read_byte(false),
             feet: frame.read_byte(false),
             hair_color: frame.read_byte(false),
             torso_color: frame.read_byte(false),
             leg_color: frame.read_byte(false),
             feet_color: frame.read_byte(false),
             skin_color: frame.read_byte(false))
    end
  end
end