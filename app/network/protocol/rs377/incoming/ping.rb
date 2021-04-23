module RuneRb::Network::RS377::PingMessage
  include RuneRb::System::Log

  def parse(_)
    log "Ping Received! [#{@header[:op_code]}]" if RuneRb::GLOBAL[:DEBUG] # Ping
  end
end