module RuneRb::Network::RS377::CommandMessage
  include RuneRb::System::Log

  def parse(context)
    command_string = read_string.split(' ')
    label = command_string.shift

    log "Parsing command: #{label}" if RuneRb::GLOBAL[:DEBUG]
    command = context.fetch_command(label&.capitalize&.to_sym)
    if command
      command.new({ context: context, world: context.world, message: self, command: command_string })
    else
      context.session.write_message(:SystemTextMessage, message: "Could not parse Command: #{label.capitalize}")
    end
  end
end