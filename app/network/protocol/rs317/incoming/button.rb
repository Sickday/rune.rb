module RuneRb::Network::RS317::ButtonClickMessage
  include RuneRb::System::Log

  def parse(context)
    id = read_short
    case id
    when 2458 then context.logout
    when 3651 then context.session.write_message(:ClearInterfacesMessage)
    else err "Unhandled button! ID: #{id}"
    end
  end
end