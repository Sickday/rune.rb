module RuneRb::Game::Entity::Commands
  class Show < RuneRb::Game::Entity::Command

    def execute
      unless @command.size >= 1
        @context.session.write(:sys_message, message: 'Invalid arguments!')
        @context.session.write(:sys_message, message: 'Usage:')
        @context.session.write(:sys_message, message: '::show <id>')
        return
      end

      log RuneRb::COL.green("Writing interface: #{@command[0].to_i}")
      @context.session.write(:interface, id: @command[0].to_i)
    end
  end
end