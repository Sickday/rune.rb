module RuneRb::Entity
  # A Command that is executed by a context entity.
  class Command
    include RuneRb::Internal::Log

    # Called when a new Command object is created
    # @param assets [Hash] the assets for command execution.
    def initialize(assets)
      @context = assets[:context]
      @world = @context.world
      @command = assets[:command]
      @frame = assets[:frame]
      @assets = assets
      execute
    end

    # Executes the Command.
    def execute; end
  end
end