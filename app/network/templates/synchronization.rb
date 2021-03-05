# Copyright (c) 2020, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module RuneRb::Network::Templates

  class SynchronizationMessage < RuneRb::Network::Message

    # Called when a new SynchronizationMessage is created
    # @param context [RuneRb::Game::Entity::Context] the Context entity to Synchronize
    def initialize(context)
      super('w',{ op_code: 81 }, :VARIABLE_SHORT)
      # Write the context's region if an update is required.
      context.session.write_message(:region, regional: context.regional) if context.flags[:region?]
      # Switch to bit access
      switch_access
      # Write Context entity movement
      write_movement(context)
      # Create a state block which to write the appearance of the context mob and surrounding mobs to.
       state_block = RuneRb::Network::Templates::StateBlockMessage.new(context)
      # Write the number of existing local players other than the context
       write_bits(8, context.locals[:players].size)
      # Update and write the local list for the context.
       write_locals(state_block, context, context.world)
      # Switch to byte access
      switch_access
      # Push the bytes from the state block.
      write_bytes(state_block)
    end

    private

    # Write an update to a context player's local list
    # @param state [RuneRb::Network::Message] the state message to write to state blocks to
    # @param context [RuneRb::Game::Entity::Context] the context to write the update for
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

      world.request(:local_contexts, context: context).each do |ctx|
        # Break if the list has reached it's max capacity.
        break if context.locals[:players].size >= 255
        # Skip this iteration if the context is the same context being synchronized, teleporting, or logged out
        next if context.locals[:players].include?(ctx) || ctx == context || ctx.flags[:teleport] || ctx.session.status[:auth] == :LOGGED_OUT

        # Add the context to the player's local player list
        # TODO: Refactor. Perhaps use ctx.index or ctx.session.id as unique identifier, but copying an entire context into each local list will likely consume a lot of memory.
        context.locals[:players] << ctx
        write_new_context(ctx, context)
        # Write the context's state
        state.write_state(ctx)
      end

      # Write the 2047 value to indicate we're breaking out of the local list update.
      write_bits(11, 2047)
    rescue StandardError => e
      err 'An error occurred during local list updating!', e
      err e.backtrace&.join("\n")
    end

    # Writes a new context to the message
    # @param context [RuneRb::Game::Entity::Context] the context to write.
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

    # Writes the movement of a context to the message
    # @param context [RuneRb::Game::Entity::Context] the context whose movement to write.
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

    # Write the placement of a context placement bits to the message
    # @param context [RuneRb::Game::Entity::Context] the context whose placement will be written.
    def write_placement(context)
      write_bits(2, 3) # Write 3 to indicate the player needs placement on a new tile.
      write_bits(2, context.position[:current][:z]) # Write the plane. 0 being ground level
      write_bit(context.flags[:region?]) # Region change?
      write_bit(context.flags[:state?]) # Update State/Appearance?
      write_bits(7, context.position[:current].local_x) # Local Y
      write_bits(7, context.position[:current].local_y) # Local X
      log "Wrote [x: #{context.position[:current].local_x}, y: #{context.position[:current].local_y}]" if RuneRb::GLOBAL[:DEBUG]
    end

    # Write the standing movement bits of a context to the message
    def write_stand
      write_bits(2, 0) # we write 0 because we're standing
    end

    # Write the walking movement bits of a context to the message
    # @param context [RuneRb::Game::Entity::Context] the mob whose movement will be written
    def write_walk(context)
      write_bits(2, 1) # we write 1 because we're walking
      write_bits(3, context.movement[:directions][:primary])
      write_bit(context.flags[:state?])
    end

    # Write running movement bits of a context to the message
    # @param context [RuneRb::Game::Entity::Context] the mob whose movement will be written
    def write_run(context)
      write_bits(2, 2) # we write 2 because we're running
      write_bits(3, context.movement[:directions][:primary])
      write_bits(3, context.movement[:directions][:secondary])
      write_bit(context.flags[:state?])
    end
  end
end