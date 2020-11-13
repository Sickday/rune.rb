module RuneRb::Commands
  # An executable Command object.
  class Command
    # Executes the Command.
    def execute(params); end
  end

  # A Command Manager object controls the loading, reloading, and execution of Command objects. It also parses and fetches pre-registered command objects based from a provided packet object.
  class Manager
    attr :commands

    def initialize(world)
      @world = world
      load_commands
      @commands = {
          Anim: RuneRb::Commands::Anim,
          Gfx: RuneRb::Commands::Gfx,
          Ascend: RuneRb::Commands::Ascend,
          Descend: RuneRb::Commands::Descend,
          Design: RuneRb::Commands::Design,
          Position: RuneRb::Commands::Position,
          To: RuneRb::Commands::To,
          Spawn: RuneRb::Commands::Spawn,
          Reload: RuneRb::Commands::Reload,
          Item: RuneRb::Commands::Item,
          Update: RuneRb::Commands::Update,
          GameObject: RuneRb::Commands::GameObject
      }.freeze
    end

    # Attempts to parse a command packet
    def parse_command(player, pkt)
      command_string = pkt.read_str.split(' ')
      label = command_string.shift
      cmd = fetch(label.capitalize.to_sym)
      if cmd
        @world.submit_work { cmd.new.execute({ player: player, world: @world, packet: pkt, command: command_string }) }
      else
        player.io.send_message("Could not parse Command with label: #{command_string.first}")
      end
    rescue StandardError => e
      puts 'An error occurred during Command parsing'
      puts e
      puts e.backtrace
    end

    private

    # Loads command files into the application.
    def load_commands
      Dir['lib/RuneRb/command/*.rb'].each do |file|
        next if File.basename(file) == 'command.rb'

        load file
      end
    end

    # Attempts to fetch a registered Command object by it's label
    # @param label [Symbol, String] the label that will be used to fetch the Command
    # @return [Command, FalseClass] returns the fetched Command object or nil.
    def fetch(label)
      @commands[label].nil? ? false : @commands[label]
    end
  end
end