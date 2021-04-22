module RuneRb::Network::RS317::MovementMessage
  include RuneRb::System::Log

  def parse(context)
    context.parse_movement(self)
  end
end