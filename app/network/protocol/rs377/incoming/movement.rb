module RuneRb::Network::RS377::MovementMessage
  include RuneRb::System::Log

  def parse(context)
    context.parse_movement(self)
  end
end