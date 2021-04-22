module RuneRb::Network::RS317::ArrowKeyMessage

  Rotation = Struct.new(:yaw, :roll) do
    include RuneRb::System::Log

    def inspect
      log! "Camera Rotation: #{RuneRb::GLOBAL[:COLOR].blue.bold("[Roll]: #{RuneRb::GLOBAL[:COLOR].cyan(self.roll)}")} || [Yaw]: #{RuneRb::GLOBAL[:COLOR].cyan(self.yaw)}"
    end
  end

  # Constructs a new ArrowKeyMessage from a buffer
  def parse(_)
    Rotation.new(read_short(false, :STD, :LITTLE), read_short(false, :STD, :LITTLE)).inspect
  end
end