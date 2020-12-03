module RuneRb::Entity::Helpers::Command
  # Attempts to parse a command packet
  # @param frame [RuneRb::Net::Frame] the frame to read from.
  def parse_command(frame)
    command_string = frame.read_string.split(' ')
    label = command_string.shift
    log "Parsing command: #{label}" if RuneRb::DEBUG
    command = fetch_command(label&.capitalize&.to_sym)
    if command
      command.new({ context: self, world: @world, frame: frame, command: command_string })
    else
      @session.write(:sys_message, message: "Could not parse Command: #{label.capitalize}")
    end
  rescue StandardError => e
    puts 'An error occurred during Command parsing'
    puts e
    puts e.backtrace
  end

  # Initializes the Instance#commands hash and populates it with recognizable commands.
  def load_commands
    @commands = {
      Animation: RuneRb::Entity::Commands::Animation,
      Ban: RuneRb::Entity::Commands::Ban,
      Graphic: RuneRb::Entity::Commands::Graphic,
      Ascend: RuneRb::Entity::Commands::Ascend,
      Descend: RuneRb::Entity::Commands::Descend,
      Design: RuneRb::Entity::Commands::Design,
      Position: RuneRb::Entity::Commands::Position,
      Show: RuneRb::Entity::Commands::Show,
      To: RuneRb::Entity::Commands::To,
      Item: RuneRb::Entity::Commands::Item
    }.freeze
  end

  # Attempts to fetch a registered Command object by it's label
  # @param label [Symbol, String] the label that will be used to fetch the Command
  # @return [RuneRb::Entity::Command, FalseClass] returns the fetched Command object or nil.
  def fetch_command(label)
    @commands[label].nil? ? false : @commands[label]
  end
end