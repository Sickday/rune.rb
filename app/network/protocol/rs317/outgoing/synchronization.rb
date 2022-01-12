module RuneRb::Network::RS317

  class ContextSynchronizationMessage < RuneRb::Network::Message

    # Called when a new SynchronizationMessage is created
    # @param context [RuneRb::Game::Entity::Context] the Context entity to Synchronize
    def initialize(context)
      super(op_code: 81, type: :VARIABLE_SHORT)

      # Switch to bit access
      @body.switch_access

      # Write Context entity movement
      write_movement(context)

      # Create a state block which to write the appearance of the context mob and surrounding mobs to.
      state_block = ContextStateBlock.new(context)

      # Write the existing local list size
      write(context.locals[:players].size, type: :bits, options: { amount: 8 })

      # write the local list for the context.
      write_locals(state_block, context, context.world)

      # Update the local list
      update_locals(state_block, context, context.world)

      # Write 2047 in 11 bits to indicate we're no longer updating the list.
      write(2047, type: :bits, options: { amount: 11 })

      # Switch to byte access
      @body.switch_access

      # Push the bytes from the state block.
      write(state_block, type: :bytes)
    end

    private

    # Write an update to a context player's local list
    # @param state [RuneRb::Network::Message] the state message to write to state blocks to
    # @param context [RuneRb::Game::Entity::Context] the context to write the update for
    def write_locals(state, context, world)
      # Write the current list
      context.locals[:players].each do |ctx_idx|
        next if ctx_idx == context.index

        # Fetch the context by it's index.
        ctx = world.entities[:players][ctx_idx]

        if ctx.nil? ||
          ctx.flags[:teleport?] ||
          ctx.session.login[:stage] == :LOGGED_OUT ||
          !ctx.position[:current].in_view?(context.position[:current])

          # Write the actual removal bits
          write(1, type: :bits, options: { amount: 1 })
          write(3, type: :bits, options: { amount: 2 })

          # Remove the contexts from each other's local list
          context.locals[:players].delete(ctx_idx)
          ctx.locals[:players].delete(context.index) unless ctx.nil?
        else
          # Write the movement and state for the context.
          write_movement(ctx) unless ctx.nil?
          state.write_state(ctx) unless ctx.nil?
        end
      end
    end

    def update_locals(state, context, world)
      world.entities[:players].each do |idx, ctx|
        # Break from this loop if the list is already full
        break if context.locals[:players].length >= 0xff

        # Skip this iteration if certain criteria are met
        next if ctx.flags[:teleport] || # Context is teleporting
          context.locals[:players].include?(idx) || # Context is already on the list
          ctx.session.login[:stage] == :LOGGED_OUT || # Context is logged out
          !context.position[:current].in_view?(ctx.position[:current]) || # Context isn't in view
          context.index == ctx.index # Context is self

        # Add this new index to the local list
        context.locals[:players] << idx
        # Write the context
        write_new_context(ctx, context)
        # Write the context's state
        state.write_state(ctx)
      end
    end

    # Writes a new context to the message
    # @param context [RuneRb::Game::Entity::Context] the context to write.
    def write_new_context(context, initial)
      # Write the context's index in the world
      write(context.index, type: :bits, options: { amount: 11 })
      # Write the context's state update flag bit
      write(context.flags[:state?], type: :bit)
      # Write the context's discard_waypoints flag bit
      write(context.flags[:discard_waypoints?], type: :bit)
      # Write y delta for the mob
      write(initial.position[:current][:y] - context.position[:current][:y], type: :bits, options: { amount: 5 })
      # Write x delta for the mob
      write(initial.position[:current][:x] - context.position[:current][:x], type: :bits, options: { amount: 5 })
    end

    # Writes the movement of a context to the message
    # @param context [RuneRb::Game::Entity::Context] the context whose movement to write.
    def write_movement(context)
      case context.movement[:type]
      when :TELEPORT
        write(true, type: :bit)
        write_placement(context)
      when :RUN
        write(true, type: :bit)
        write_run(context)
      when :WALK
        write(true, type: :bit)
        write_walk(context)
      else
        if context.flags[:state?]
          write(true, type: :bit)
          write_stand
        else
          write(false, type: :bit)
        end
      end
    end

    # Write the placement of a context placement bits to the message
    # @param context [RuneRb::Game::Entity::Context] the context whose placement will be written.
    def write_placement(context)
      write(3, type: :bits, options: { amount: 2 }) # Write 3 to indicate the player needs placement on a new tile.
      write(context.position[:current][:z] || 0, type: :bits, options: { amount: 2 }) # Write the plane. 0 being ground level
      write(context.flags[:region?] ? 0 : 1, type: :bits, options: { amount: 1 }) # Region change?
      write(context.flags[:state?], type: :bit) # Update State/Appearance?
      write(context.position[:current].local_x, type: :bits, options: { amount: 7 }) # Local Y
      write(context.position[:current].local_y, type: :bits, options: { amount: 7 }) # Local X
      log "Wrote [x: #{context.position[:current].local_x}, y: #{context.position[:current].local_y}]"
    end

    # Write the standing movement bits of a context to the message
    def write_stand
      write(0, type: :bits, options: { amount: 2 }) # we write 0 because we're standing
    end

    # Write the walking movement bits of a context to the message
    # @param context [RuneRb::Game::Entity::Context] the mob whose movement will be written
    def write_walk(context)
      write(1, type: :bits, options: { amount: 2 }) # we write 1 because we're walking
      write(context.movement[:directions][:primary], type: :bits, options: { amount: 3 })
      write(context.flags[:state?], type: :bit)
    end

    # Write running movement bits of a context to the message
    # @param context [RuneRb::Game::Entity::Context] the mob whose movement will be written
    def write_run(context)
      write(2, type: :bits, options: { amount: 2 }) # we write 2 because we're running
      write(context.movement[:directions][:primary], type: :bits, options: { amount: 3 } )
      write(context.movement[:directions][:secondary], type: :bits, options: { amount: 3 })
      write(context.flags[:state?], type: :bit)
    end
  end
end

# Copyright (c) 2021, Patrick W.
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