module RuneRb::World::CommandHelper
  # Initializes the Instance#commands hash and populates it with recognizable commands.
  def init_commands
    @commands = {
      Animation: RuneRb::World::Commands::Animation,
      Ban: RuneRb::World::Commands::Ban,
      Graphic: RuneRb::World::Commands::Graphic,
      Ascend: RuneRb::World::Commands::Ascend,
      Descend: RuneRb::World::Commands::Descend,
      Design: RuneRb::World::Commands::Design,
      Position: RuneRb::World::Commands::Position,
      Show: RuneRb::World::Commands::Show,
      To: RuneRb::World::Commands::To,
      Item: RuneRb::World::Commands::Item
    }.freeze
  end

  # Attempts to fetch a registered Command object by it's label
  # @param label [Symbol, String] the label that will be used to fetch the Command
  # @return [RuneRb::World::Command, FalseClass] returns the fetched Command object or nil.
  def fetch_command(label)
    @commands[label].nil? ? false : @commands[label]
  end
end