module RuneRb::Network::RS377::MouseClickMessage

  Click = Struct.new(:delay, :right?, :x, :y) do
    include RuneRb::System::Log

    def inspect
      log! RuneRb::GLOBAL[:COLOR].blue("[DELAY_SINCE:] #{self.delay}"),
           self.right? ? RuneRb::GLOBAL[:COLOR].cyan.bold("[X:] #{self.x}") : RuneRb::GLOBAL[:COLOR].blue.bold("[X:] #{self.x}"),
           self.right? ? RuneRb::GLOBAL[:COLOR].cyan.bold("[X:] #{self.x}") : RuneRb::GLOBAL[:COLOR].blue.bold("[X:] #{self.x}")

    end
  end

  def parse(_)
    data = read_int
    coordinates = data & 0x3FFFF
    Click.new((data >> 20) * 50, (data >> 19 & 0x1) == 1, coordinates & 765, coordinates / 765).inspect
  end
end
