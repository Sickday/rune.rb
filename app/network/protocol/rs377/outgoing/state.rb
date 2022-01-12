module RuneRb::Network::RS377

  class ContextStateBlock < RuneRb::Network::Message
    using RuneRb::Utils::Patches::StringRefinements

    # Writes the appearance of a Context entity
    # @param context [RuneRb::Game::Entity::Context] the context whose appearance will be written
    def initialize(context)
      super(type: :RAW)
      write_state(context)
    end

    # Writes the state of a context to a message
    # @param context [RuneRb::Game::Entity::Context] the context whose state to write.
    def write_state(context)
      # Make the mask
      mask = 0
      # Attributes:
      # Animation
      mask |= 0x8 if context.flags[:animation?]
      # Forced Chat
      mask |= 0x10 if context.flags[:force_chat?]
      # ForcedMove
      mask |= 0x100 if context.flags[:force_move?]
      # Face Entity
      mask |= 0x1 if context.flags[:face_mob?]
      # Face Coordinates
      mask |= 0x2 if context.flags[:turn_to?]
      # Graphics
      mask |= 0x200 if context.flags[:graphic?]
      # Appearance
      mask |= 0x4 if context.flags[:state?]
      # Primary Hit
      mask |= 0x80 if context.flags[:primary_hit?]
      # Chat
      mask |= 0x40 if context.flags[:chat?]
      # Secondary Hit
      mask |= 0x400 if context.flags[:secondary_hit?]
      # Append the mask
      if mask >= 0x100
        mask |= 0x20
        write(mask, type: :short, order: 'LITTLE')
      else
        write(mask, type: :byte)
      end

      write_animation(context.animation) if context.flags[:animation?]
      # write_forced_chat(context.forced_chat) if context.flags[:forced_chat?]
      write_graphic(context.graphic) if context.flags[:graphic?]
      write_appearance(context) if context.flags[:state?]
      write_chat(context.message, context.profile.rights) if context.flags[:chat?]
    end

    private

    # Writes the appearance of a Context Mob to the message.
    # @param context [RuneRb::Game::Entity::Context] the the context whose appearance will be written.
    def write_appearance(context)
      appearance_buffer = RuneRb::Network::Buffer.new('w')

      # Gender
      appearance_buffer.write(context.appearance[:gender], type: :byte)
      # Skulled
      appearance_buffer.write(context.appearance[:skulled] ? 1 : -1, type: :byte)
      # HeadIcon
      appearance_buffer.write(context.appearance[:head_icon], type: :byte)

      # Write the appearance normally if there is no morphing.
      if context.appearance[:mob_id] == -1
        # write_equipment(appearance_buffer, context.equipment, context.appearance)
        write_model_color(appearance_buffer, context.appearance)
        write_model_animation(appearance_buffer, context.appearance)
      else
        # Else write the morph
        write_morph(appearance_buffer, context.appearance)
      end

      # Player's name
      appearance_buffer.write(context.profile[:name_hash], type: :long)

      # Combat Level
      appearance_buffer.write(context.combat_level, type: :byte)

      # Skill Level
      appearance_buffer.write(context.total_level, type: :short)

      #binding.pry

      # Size of the State Block
      write(appearance_buffer.length, type: :byte)
      write(appearance_buffer.snapshot, type: :reverse_bytes)
    end

    # Writes the mob morphing bytes of a context to the message
    # @param buffer [RuneRb::Network::Buffer] the buffer that is written to.
    # @param appearance [RuneRb::System::Database::Appearance] the context entity whose mob morphing bytes will be written to the message.
    def write_morph(buffer, appearance)
      buffer.write(0xFF, type: :byte)
      buffer.write(0xFF, type: :byte)
      buffer.write(appearance[:mob_id], type: :short, mutation: :STD, order: 'BIG')
    end

    # Writes the equipment of a context to the message.
    # @param equipment [Hash] the context's equipment database
    # @param buffer [RuneRb::Network::Buffer] the buffer that is written to.
    # @param appearance [RuneRb::System::Database::Appearance] the context's appearance model
    def write_equipment(buffer, equipment, appearance)

      # HAT SLOT
      if equipment[:HAT].id != -1
        buffer.write(0x200 + equipment[:HAT].id, type: :short, mutation: :STD, order: 'BIG')
      else
        message.write(0, type: :byte)
      end

      # CAPE SLOT
      if equipment[:CAPE].id != -1
        message.write(0x200 + equipment[:CAPE].id, type: :short, mutation: :STD, order: 'BIG')
      else
        buffer.write(0, type: :byte)
      end

      # AMULET SLOT
      if equipment[:AMULET].id != -1
        buffer.write(0x200 + equipment[:AMULET].id, type: :short)
      else
        buffer.write(0, type: :byte)
      end

      # WEAPON SLOT
      if equipment[:WEAPON].id != -1
        buffer.write(0x200 + equipment[:WEAPON].id, type: :short)
      else
        buffer.write(0, type: :byte)
      end

      # CHEST SLOT
      if equipment[:CHEST].id != -1 # Item is in slot?
        buffer.write(0x200 + equipment[:CHEST].id, type: :short) # Write mask + item id
      else # Not wearing anything in slot?
        buffer.write(0x100 + appearance[:chest], type: :short) # Write mask + chest appearance id
      end

      # SHIELD SLOT
      if equipment[:SHIELD].id != -1 # Item is in slot?
        buffer.write(0x200 + equipment[:SHIELD].id, type: :short) # Write mask + item id
      else # Not wearing anything in slot?
        buffer.write(0, type: :byte) # Write mask + chest appearance id
      end

      # ARMS WITH PLATEBODY SUPPORT.
      if equipment[:CHEST].id != -1
        if %w[platebody brassard leatherbody].any? { |type| equipment[:CHEST].definition[:name].include?(type) }
          buffer.write(0, type: :byte)
        else
          buffer.write(0x100 + appearance[:arms], type: :short)
        end
      else
        buffer.write(0x100 + appearance[:arms], type: :short)
      end

      # LEGS
      if equipment[:LEGS].id != -1
        buffer.write(0x200 + equipment[:LEGS].id, type: :short)
      else
        buffer.write(0x100 + appearance[:legs], type: :short)
      end

      # HELM
      if equipment[:HAT].id != -1 && equipment[:HAT].definition[:full_mask] == true
        buffer.write(0, type: :byte)
      else
        buffer.write(0x100 + appearance[:head], type: :short)
      end

      # GLOVES
      if equipment[:GLOVES].id != -1
        buffer.write(0x200 + equipment[:GLOVES].id, type: :short)
      else
        buffer.write(0x100 + appearance[:hands], type: :short)
      end

      # BOOTS
      if equipment[:BOOTS].id != -1
        buffer.write(0x200 + equipment[:BOOTS].id, type: :short)
      else
        buffer.write(0x100 + appearance[:feet], type: :short)
      end

      # BEARD
      if (equipment[:HAT].id != -1) && (equipment[:HAT].definition[:full_mask] || appearance[:gender] == 1)
        buffer.write(0, type: :byte)
      else
        buffer.write(0x100 + appearance[:beard], type: :short)
      end
    rescue StandardError => e
      err 'An error occurred while writing equipment!', e
      err e.backtrace&.join("\n")
    end

    # Writes the model color of a context to the buffer.
    # @param appearance [RuneRb::System::Database::Appearance] the appearance of the context whose model color will be written to the buffer
    def write_model_color(buffer, appearance)
      buffer.write(appearance[:hair_color], type: :byte)       # Hair color
      buffer.write(appearance[:torso_color], type: :byte)      # Torso color
      buffer.write(appearance[:leg_color], type: :byte)        # Leg color
      buffer.write(appearance[:feet_color], type: :byte)       # Feet color
      buffer.write(appearance[:skin_color], type: :byte)       # Skin color
    end

    # Writes the model animation of a context to the buffer.
    # @param appearance [RuneRb::System::Database::Appearance] the appearance of the context whose model animation will be written to the buffer.
    def write_model_animation(buffer, appearance)
      buffer.write(appearance[:stand_emote], type: :short)           # Stand Anim
      buffer.write(appearance[:stand_turn_emote], type: :short)      # StandTurn Anim
      buffer.write(appearance[:walk_emote], type: :short)            # Walk Anim
      buffer.write(appearance[:turn_180_emote], type: :short)        # Turn 180
      buffer.write(appearance[:turn_90_cw_emote], type: :short)      # Turn 90 Clockwise
      buffer.write(appearance[:turn_90_ccw_emote], type: :short)     # Turn 90 Counter-Clockwise
      buffer.write(appearance[:run_emote], type: :short)             # Run Anim
    end

    # Writes a chat to the buffer
    # @param message [RuneRb::Game::Entity::ChatMessage] the message to write.
    # @param rights [Integer] the rights of the context whose message is being written
    def write_chat(message, rights)
      write((message.colors << 8 | message.effects), type: :short, order: 'LITTLE')
      write(rights, type: :byte)
      write(message.text.size, mutation: :sub)
      write(message.text.reverse, type: :reverse_bytes)
    end

    # Writes the message the context will be forced to display.
    # @param message [String] the message
    def write_forced_chat(message)
      write(message, type: :string)
    end

    # Writes a graphic to the message
    # @param graphic [RuneRb::Game::Entity::Graphic] the graphic to write.
    def write_graphic(graphic)
      write(graphic.id, type: :short)
      write((graphic.height << 16 | graphic.delay), type: :int)
    end

    # Write the animation that should be played by the context.
    # @param animation [RuneRb::Game::Entity::Animation] the animation to write.
    def write_animation(animation)
      write(animation.id, type: :short)
      write(animation.delay, type: :byte, mutation: :NEG)
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