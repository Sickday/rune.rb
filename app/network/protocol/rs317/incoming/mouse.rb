module RuneRb::Network::RS317::MouseEventMessage

  Movement = Struct.new(:clicks, :x, :y, :delta?) do
    include RuneRb::System::Log

    def inspect
      log! RuneRb::GLOBAL[:COLOR].blue("[CLICK_COUNT:] #{self.clicks}"),
           self.delta? ? RuneRb::GLOBAL[:COLOR].cyan.bold("[X:] #{self.x}") : RuneRb::GLOBAL[:COLOR].blue.bold("[X:] #{self.x}"),
           self.delta? ? RuneRb::GLOBAL[:COLOR].cyan.bold("[X:] #{self.x}") : RuneRb::GLOBAL[:COLOR].blue.bold("[X:] #{self.x}")
    end
  end

  # Constructs a parsable MouseEventMessage from a buffer.
  def parse(_)
    if @header[:length] == 2
      data = read_short
      return Movement.new(data >> 12, data >> 6 & 0x3f, data & 0x3f, true)
    elsif @header[:length] == 3
      data = read_medium & ~0x800000
    else
      data = read_int & ~0xc0000000
    end
    Movement.new(data >> 19, (data & 0x7f) % 765, (data & 0x7f) / 765).inspect
  end
end