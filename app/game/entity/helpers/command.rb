module RuneRb::Entity::Helpers::Command
  # Attempts to parse a command packet
  # @param frame [RuneRb::Net::Frame] the frame to read from.
  def parse_command(frame)
    command_string = frame.read_string.split(' ')
    label = command_string.shift
    log "Parsing command: #{label}"
    command = @world.fetch_command(label&.capitalize&.to_sym)
    if command
      command.new({ context: self, world: @world, frame: frame, command: command_string })
    else
      @session.write(:sys_message, message: "Could not parse Command: #{command_string.first}")
    end
  rescue StandardError => e
    puts 'An error occurred during Command parsing'
    puts e
    puts e.backtrace
  end
end