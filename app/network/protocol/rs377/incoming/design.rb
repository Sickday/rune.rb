module RuneRb::Network::RS377::ContextDesignMessage
  include RuneRb::System::Log

  def parse(context)
    context.appearance.update(gender: read_byte, head: read_byte, beard: read_byte,
                              chest: read_byte, arms: read_byte, hands: read_byte,
                              legs: read_byte, feet: read_byte, hair_color: read_byte,
                              torso_color: read_byte, leg_color: read_byte, feet_color: read_byte,
                              skin_color: read_byte)
    context.update(:state)
  end
end