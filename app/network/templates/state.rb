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

  class StateBlockMessage < RuneRb::Network::Message
    using RuneRb::System::Patches::StringRefinements

    # Writes the appearance of a Context entity
    # @param context [RuneRb::Game::Entity::Context] the context whose appearance will be written
    def initialize(context)
      super('w')
      write_state(context)
    end

    # Writes the state of a context to a message
    # @param context [RuneRb::Game::Entity::Context] the context whose state to write.
    def write_state(context)
      # Make the mask
      mask = 0
      # Attributes:
      # ForcedMove
      mask |= 0x400 if context.flags[:force_move?]
      # Graphics
      mask |= 0x100 if context.flags[:graphic?]
      # Animation
      mask |= 0x8 if context.flags[:animation?]
      # Forced Chat
      mask |= 0x4 if context.flags[:force_chat?]
      # Chat
      mask |= 0x80 if context.flags[:chat?]
      # Face Entity
      mask |= 0x1 if context.flags[:face_mob?]
      # Appearance
      mask |= 0x10 if context.flags[:state?]
      # Face Coordinates
      mask |= 0x2 if context.flags[:turn_to?]
      # Primary Hit
      mask |= 0x20 if context.flags[:primary_hit?]
      # Secondary Hit
      mask |= 0x200 if context.flags[:secondary_hit?]
      # Append the mask
      if mask >= 0x100
        mask |= 0x40
        write(mask, { type: :short, mutation: :STD, order: :LITTLE })
      else
        write(mask, type: :byte)
      end

      write_graphic(context.graphic) if context.flags[:graphic?]
      write_animation(context.animation) if context.flags[:animation?]
      write_chat(context.message, context.profile.rights) if context.flags[:chat?]
      write_appearance(context) if context.flags[:state?]
    end

    private

    # Writes the appearance of a Context Mob to the message.
    # @param context [RuneRb::Game::Entity::Context] the the context whose appearance will be written.
    def write_appearance(context)
      appearance_message = RuneRb::Network::Message.new('w', { op_code: -1 })
      # Gender
      appearance_message.write(context.appearance[:gender], type: :byte)
      # HeadIcon
      appearance_message.write(context.appearance[:head_icon], type: :byte)
      # Write the appearance normally if there is no morphing.
      if context.appearance[:mob_id] == -1
        write_equipment(appearance_message, context.equipment, context.appearance)
        write_model_color(appearance_message, context.appearance)
        write_model_animation(appearance_message, context.appearance)
      else
        # Else write the morph
        write_morph(appearance_message, context.appearance)
      end
      # Player's name
      appearance_message.write(context.profile[:name_hash], type: :long)
      # Combat Level
      appearance_message.write(context.profile.stats.combat.to_i, type: :byte)
      # Skill Level
      appearance_message.write(context.profile.stats.total, type: :short)
      # Size of the State Block
      write(appearance_message.peek.bytesize, type: :byte, mutation: :C)
      log! "Wrote size #{appearance_message.peek.bytesize}"
      log! "Payload: <<#{appearance_message.peek}>>"
      write(appearance_message, type: :bytes)
    end

    # Writes the mob morphing bytes of a context to the message
    # @param appearance [RuneRb::System::Database::Appearance] the context entity whose mob morphing bytes will be written to the message.
    def write_morph(message, appearance)
      message.write(0xff, type: :byte)
      message.write(0xff, type: :byte)
      message.write(appearance[:mob_id], type: :short)
    end

    # Writes the equipment of a context to the message.
    # @param equipment [Hash] the context's equipment database
    # @param appearance [RuneRb::System::Database::Appearance] the context's appearance model
    def write_equipment(message, equipment, appearance)
      # HAT SLOT
      if equipment[0] != -1
        message.write(0x200 + equipment[0].id, type: :short)
      else
        message.write(0, type: :byte)
      end

      # CAPE SLOT
      if equipment[1] != -1
        message.write(0x200 + equipment[1].id, type: :short)
      else
        message.write(0, type: :byte)
      end

      # AMULET SLOT
      if equipment[2] != -1
        message.write(0x200 + equipment[2].id, type: :short)
      else
        message.write(0, type: :byte)
      end

      # WEAPON SLOT
      if equipment[3] != -1
        message.write(0x200 + equipment[3].id, type: :short)
      else
        message.write(0, type: :byte)
      end

      # TORSO SLOT
      if equipment[4] != -1 # Item is in slot?
        message.write(0x200 + equipment[4].id, type: :short) # Write mask + item id
      else # Not wearing anything in slot?
        message.write(0x100 + appearance[:chest], type: :short) # Write mask + chest appearance id
      end

      # SHIELD SLOT
      if equipment[5] != -1 # Item is in slot?
        message.write(0x200 + equipment[5].id, type: :short) # Write mask + item id
      else # Not wearing anything in slot?
      message.write(0, type: :byte) # Write mask + chest appearance id
      end

      # ARMS WITH PLATEBODY SUPPORT.
      if equipment[4] != -1
        if %w[platebody brassard leatherbody].any? { |type| equipment[4].definition[:name].include?(type) }
          message.write(0, type: :byte)
        else
          message.write(0x100 + appearance[:arms], type: :short)
        end
      else
        message.write(0x100 + appearance[:arms], type: :short)
      end

      # LEGS
      if equipment[7] != -1
        message.write(0x200 + equipment[7].id, type: :short)
      else
        message.write(0x100 + appearance[:legs], type: :short)
      end

      # HELM
      if equipment[0] != -1 && equipment[0].definition[:full_mask] == true
        message.write(0, type: :byte)
      else
        message.write(0x100 + appearance[:head], type: :short)
      end

      # GLOVES
      if equipment[9] != -1
        message.write(0x200 + equipment[9].id, type: :short)
      else
        message.write(0x100 + appearance[:hands], type: :short)
      end

      # BOOTS
      if equipment[10] != -1
        message.write(0x200 + equipment[10].id, type: :short)
      else
        message.write(0x100 + appearance[:feet], type: :short)
      end

      # BEARD
      if (equipment[0] != -1) && (equipment[0].definition[:full_mask] || appearance[:gender] == 1)
        message.write(0, type: :byte)
      else
        message.write(0x100 + appearance[:beard], type: :short)
      end
    rescue StandardError => e
      err 'An error occurred while writing equipment!', e
      err e.backtrace&.join("\n")
    end

    # Writes the model color of a context to the message.
    # @param appearance [RuneRb::System::Database::Appearance] the appearance of the context whose model color will be written to the message
    def write_model_color(message, appearance)
      message.write(appearance[:hair_color], type: :byte)       # Hair color
      message.write(appearance[:torso_color], type: :byte)      # Torso color
      message.write(appearance[:leg_color], type: :byte)        # Leg color
      message.write(appearance[:feet_color], type: :byte)       # Feet color
      message.write(appearance[:skin_color], type: :byte)       # Skin color
    end

    # Writes the model animation of a context to the message.
    # @param appearance [RuneRb::System::Database::Appearance] the appearance of the context whose model animation will be written to the message.
    def write_model_animation(message, appearance)
      message.write(appearance[:stand], type: :short)           # Stand Anim
      message.write(appearance[:stand_turn], type: :short)      # StandTurn Anim
      message.write(appearance[:walk], type: :short)            # Walk Anim
      message.write(appearance[:turn_180], type: :short)        # Turn 180
      message.write(appearance[:turn_90_cw], type: :short)      # Turn 90 Clockwise
      message.write(appearance[:turn_90_ccw], type: :short)     # Turn 90 Counter-Clockwise
      message.write(appearance[:run], type: :short)             # Run Anim
    end

    # Writes a chat to the message
    # @param message [RuneRb::Game::Entity::Message] the message to write.
    # @param rights [Integer] the rights of the context whose message is being written
    def write_chat(message, rights)
      write((message.colors << 8 | message.effects), { type: :short, mutation: :STD, order: :LITTLE })
      write(rights, type: :byte)
      write(message.text.size, { type: :byte, mutation: :C })
      write(message.text.reverse, type: :reverse_bytes)
    end

    # Writes a graphic to the message
    # @param graphic [RuneRb::Game::Entity::Graphic] the graphic to write.
    def write_graphic(graphic)
      write(graphic.id, type: :short)
      write(graphic.height << 16 | graphic.delay, type: :int)
    end

    # Writes a context animation to a message.
    # @param animation [RuneRb::Game::Entity::Animation] the animation to write.
    def write_animation(animation)
      write(animation.id, { type: :short, mutation: :STD, order: :LITTLE })
      write(animation.delay, { type: :byte, mutation: :C })
    end
  end
end