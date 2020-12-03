module RuneRb::Net::Meta
  class SynchronizationFrame < RuneRb::Net::MetaFrame

    # Called when a new SynchronizationFrame is created
    # @param context [RuneRb::Entity::Context] the context for which the frame will be made.
    def initialize(context)
      super(81, false, true)
      parse(context)
    end

    private

    # Attempts to parse and generate a SynchronizationFrame for the context mob
    def parse(context)
      # Write the context's region if an update is required.
      context.session.write(:region, regional: context.regional) if context.flags[:region?]
      # Switch to bit access
      switch_access
      # Write Context entity movement
      write_movement(context)
      # Create a state block which to write the appearance of the context mob and surrounding mobs to.
      state_block = RuneRb::Net::Meta::StateBlock.new(context)
      # Write the number of existing local players other than the context
      write_bits(8, context.locals[:players].size)
      # Update and write the local list for the context.
      write_locals(state_block, context, context.world)
      # Switch to byte access
      switch_access
      # Push the bytes from the state block.
      write_bytes(state_block)
    end

    # Write an update to a context player's local list
    # @param state [RuneRb::Network::MetaFrame] the state frame to write to state blocks to
    # @param context [RuneRb::Entity::Context] the context to write the update for
    def write_locals(state, context, world)
      # Update the existing list of local players
      context.locals[:players].each do |ctx|
        # Remove the context if it's teleporting, no longer in view, logged out, or is no longer included in the context's world instance's player list.
        if ctx.flags[:teleport?] ||
           ctx.session.status[:auth] == :LOGGED_OUT ||
           !ctx.position[:current].in_view?(context.position[:current]) ||
           !world.entities[:players].values.include?(ctx)
          # Write the actual removal bits
          write_bits(1, 1)
          write_bits(2, 3)
          # Remove the contexts from each other's local list
          context.locals[:players].delete(ctx)
        else
          # Write the movement and state for the context.
          write_movement(ctx)
          state.write_state(ctx)
        end
      end
      # TODO: this is an expensive operation to run as it will loop through all context mobs within the attached world instance. This could possibly be less expensive if we used a region list instead of the world's entity list.
      world.request(:local_contexts, context: context).difference(context.locals[:players]).each do |ctx|
        # Break if the list has reached it's max capacity.
        break if context.locals[:players].size >= 255
        # Skip this iteration if the context is the same context being synchronized, teleporting, or logged out
        next if context.locals[:players].include?(ctx) || ctx == context || ctx.flags[:teleport] || ctx.session.status[:auth] == :LOGGED_OUT

        # Add the context to the player's local player list
        context.locals[:players] << ctx
        write_new_context(ctx, context)
        # Write the context's state
        state.write_state(ctx)
      end
      # Write the 2047 value to indicate we're breaking out of the local list update.
      write_bits(11, 2047)
    rescue StandardError => e
      err 'An error occurred during local list updating!'
      puts e
      puts e.backtrace
    end

    # Writes a new context to the frame
    # @param context [RuneRb::Entity::Context] the context to write.
    def write_new_context(context, initial)
      # Write the context's index in the world
      write_bits(11, context.index)
      # Write the context's state update flag bit and it's state
      write_bit(context.flags[:state?])
      # Write the context's discard_waypoints flag bit
      write_bit(context.flags[:discard_waypoints?])
      # Write deltas for the mob
      write_bits(5, context.position[:current][:y] - initial.position[:current][:y])
      write_bits(5, context.position[:current][:x] - initial.position[:current][:x])
    end

    # Writes the movement of a context to the frame
    # @param context [RuneRb::Entity::Context] the context whose movement to write.
    def write_movement(context)
      case context.movement[:type]
      when :TELEPORT
        write_bit(true)
        write_placement(context)
      when :RUN
        write_bit(true)
        write_run(context)
      when :WALK
        write_bit(true)
        write_walk(context)
      else
        if context.flags[:state?]
          write_bit(true)
          write_stand
        else
          write_bit(false)
        end
      end
    end

    # Write the placement of a context placement bits to the frame
    # @param context [RuneRb::Entity::Context] the context whose placement will be written.
    def write_placement(context)
      write_bits(2, 3) # Write 3 to indicate the player needs placement on a new tile.
      write_bits(2, context.position[:current][:z]) # Write the plane. 0 being ground level
      write_bit(context.flags[:region?]) # Region change?
      write_bit(context.flags[:state?]) # Update State/Appearance?
      write_bits(7, context.position[:current].local_x) # Local Y
      write_bits(7, context.position[:current].local_y) # Local X
      log "Wrote [x: #{context.position[:current].local_x}, y: #{context.position[:current].local_y}]" if RuneRb::DEBUG
    end

    # Write the standing movement bits of a context to the frame
    def write_stand
      write_bits(2, 0) # we write 0 because we're standing
    end

    # Write the walking movement bits of a context to the frame
    # @param context [RuneRb::Entity::Context] the mob whose movement will be written
    def write_walk(context)
      write_bits(2, 1) # we write 1 because we're walking
      write_bits(3, context.movement[:directions][:primary])
      write_bit(context.flags[:state?])
    end

    # Write running movement bits of a context to the frame
    # @param context [RuneRb::Entity::Context] the mob whose movement will be written
    def write_run(context)
      write_bits(2, 2) # we write 2 because we're running
      write_bits(3, context.movement[:directions][:primary])
      write_bits(3, context.movement[:directions][:secondary])
      write_bit(context.flags[:state?])
    end
  end
end