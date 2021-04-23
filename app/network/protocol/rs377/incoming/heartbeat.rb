module RuneRb::Network::RS377::HeartbeatMessage
  include RuneRb::System::Log

  def parse(_)
    log! RuneRb::GLOBAL[:COLOR].magenta.bold "Received heartbeat" if RuneRb::GLOBAL[:DEBUG]
  end
end