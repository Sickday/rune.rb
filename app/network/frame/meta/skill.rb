module RuneRb::Network::Meta
  # A single Skill Slot
  class SkillSlotFrame < RuneRb::Network::MetaFrame

    # Called when a new SkillSlotFrame is created.
    def initialize(data)
      super(134)
      parse(data)
    end

    private

    # Parses the skill slot frame data and writes it to the payload.
    def parse(data)
      write_byte(data[:skill_id])
      write_int(data[:experience], :STD, :MIDDLE)
      write_byte(data[:level])
    end
  end
end