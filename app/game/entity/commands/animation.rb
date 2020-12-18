module RuneRb::Game::Entity::Commands
  class Animation < RuneRb::Game::Entity::Command
    # Executes the ::anim command.
    def execute
      return unless @assets[:command].length >= 1

      @assets[:context].update(:animation, animation: RuneRb::Game::Entity::Animation.new(@assets[:command][0].to_i, @assets[:command][1].to_i || 0))
    end
  end
end