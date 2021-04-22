module RuneRb::Network::RS317::PingMessage
  include RuneRb::System::Log

  def parse(_)
    log "Ping Received! [#{@header[:op_code]}]" if RuneRb::GLOBAL[:DEBUG] # Ping
  end
end