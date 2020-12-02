module RuneRb::Entity::Helpers::Button
  # Parses a button press
  # @param frame [RuneRb::Net::Frame] the frame payload to parse
  def parse_button(frame)
    id = frame.read_short
    case id
    when 2458 then @world.release(self)
    when 3651 then @session.write(:clear_interfaces)
    else err "Unhandled button! ID: #{id}"
    end
  end
end