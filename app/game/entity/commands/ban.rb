module RuneRb::Entity::Commands
  # Bans a profile from the network.
  class Ban < RuneRb::Entity::Command
    def execute
      return unless @assets[:command][0].size > 0

      begin
        # First we update the banned status for the user
        RuneRb::Database::PROFILES[:profile]
            .where(name: @assets[:command][0])
            .update(banned: true)
        @assets[:context].session.write(:sys_message, message: "The player, #{@assets[:command][0]}, has been banned.")
      rescue StandardError => e
        err "An error occurred retrieving profile for: #{@assets[:command][0]}!", e
        puts e.backtrace
        return
      end

      # Next, we log the player out if they're connected to the same world instance.
      target = @assets[:context].world.request(:context, name: @assets[:command][0])
      if target
        @assets[:context].world.release(target)
      else
        @assets[:context].session.write(:sys_message, message: "Could not locate #{@assets[:command][0]} in any existing world instances.")
      end
    end
  end
end