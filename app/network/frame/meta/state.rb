module RuneRb::Net::Meta
  class StateBlock < RuneRb::Net::MetaFrame
    using RuneRb::Patches::StringOverrides

    # Writes the appearance of a Context entity
    # @param context [RuneRb::Entity::Context] the context whose appearance will be written
    def initialize(context)
      super(-1)
      write_state(context)
    end

    # Writes the state of a context to a frame
    # @param context [RuneRb::Entity::Context] the context whose state to write.
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
        write_short(mask, :STD, :LITTLE)
      else
        write_byte(mask)
      end

      write_graphic(context.graphic) if context.flags[:graphic?]
      write_animation(context.animation) if context.flags[:animation?]
      write_chat(context.message) if context.flags[:chat?]
      write_appearance(context) if context.flags[:state?]
    end

    private

    # Writes the appearance of a Context Mob to the frame.
    # @param context [RuneRb::Entity::Context] the the context whose appearance will be written.
    def write_appearance(context)
      appearance_frame = RuneRb::Net::MetaFrame.new(-1)
      # Gender
      appearance_frame.write_byte(context.appearance[:gender])
      # HeadIcon
      appearance_frame.write_byte(context.appearance[:head_icon])
      # Write the appearance normally if there is no morphing.
      if context.appearance[:mob_id] == -1
        write_equipment(appearance_frame, context.equipment, context.appearance)
        write_model_color(appearance_frame, context.appearance)
        write_model_animation(appearance_frame, context.appearance)
      else
        # Else write the morph
        write_morph(appearance_frame, context.appearance)
      end
      # Player's name
      appearance_frame.write_long(context.profile.name.to_base37)
      # Combat Level
      appearance_frame.write_byte(context.profile.stats.combat)
      # Skill Level
      appearance_frame.write_short(context.profile.stats.total)
      # Size of the State Block
      write_byte(appearance_frame.size, :C)
      write_bytes(appearance_frame)
    end

    # Writes the mob morphing bytes of a context to the frame
    # @param appearance [RuneRb::Database::Appearance] the context entity whose mob morphing bytes will be written to the frame.
    def write_morph(frame, appearance)
      frame.write_byte(0xff)
      frame.write_byte(0xff)
      frame.write_short(appearance[:mob_id])
    end

    # Writes the equipment of a context to the frame.
    # @param equipment [Hash] the context's equipment data
    # @param appearance [RuneRb::Database::Appearance] the context's appearance model
    def write_equipment(frame, equipment, appearance)
      # HAT SLOT
      if equipment[0] != -1
        frame.write_short(0x200 + equipment[0].id)
      else
        frame.write_byte(0)
      end

      # CAPE SLOT
      if equipment[1] != -1
        frame.write_short(0x200 + equipment[1].id)
      else
        frame.write_byte(0)
      end

      # AMULET SLOT
      if equipment[2] != -1
        frame.write_short(0x200 + equipment[2].id)
      else
        frame.write_byte(0)
      end

      # WEAPON SLOT
      if equipment[3] != -1
        frame.write_short(0x200 + equipment[3].id)
      else
        frame.write_byte(0)
      end

      # TORSO SLOT
      if equipment[4] != -1 # Item is in slot?
        frame.write_short(0x200 + equipment[4].id) # Write mask + item id
      else # Not wearing anything in slot?
        frame.write_short(0x100 + appearance[:chest]) # Write mask + chest appearance id
      end

      # SHIELD SLOT
      if equipment[5] != -1 # Item is in slot?
        frame.write_short(0x200 + equipment[5].id) # Write mask + item id
      else # Not wearing anything in slot?
        frame.write_byte(0) # Write mask + chest appearance id
      end

      # ARMS WITH PLATEBODY SUPPORT.
      if equipment[4] != -1
        if %w[platebody brassard leatherbody].any? { |type| equipment[4].definition[:name].include?(type) }
          frame.write_byte(0)
        else
          frame.write_short(0x100 + appearance[:arms])
        end
      else
        frame.write_short(0x100 + appearance[:arms])
      end

      # LEGS
      if equipment[7] != -1
        frame.write_short(0x200 + equipment[7].id)
      else
        frame.write_short(0x100 + appearance[:legs])
      end

      # HELM
      if equipment[0] != -1 && equipment[0].definition[:full_mask] == true
        frame.write_byte(0)
      else
        frame.write_short(0x100 + appearance[:head])
      end

      # GLOVES
      if equipment[9] != -1
        frame.write_short(0x200 + equipment[9].id)
      else
        frame.write_short(0x100 + appearance[:hands])
      end

      # BOOTS
      if equipment[10] != -1
        frame.write_short(0x200 + equipment[10].id)
      else
        frame.write_short(0x100 + appearance[:feet])
      end

      # BEARD
      if (equipment[0] != -1) && (equipment[0].definition[:full_mask] || appearance[:gender] == 1)
        frame.write_byte(0)
      else
        frame.write_short(0x100 + appearance[:beard])
      end
    rescue StandardError => e
      err 'An error occurred while writing equipment!'
      puts e
      puts e.backtrace
    end

    # Writes the model color of a context to the frame.
    # @param appearance [RuneRb::Database::Appearance] the appearance of the context whose model color will be written to the frame
    def write_model_color(frame, appearance)
      frame.write_byte(appearance[:hair_color])       # Hair color
      frame.write_byte(appearance[:torso_color])      # Torso color
      frame.write_byte(appearance[:leg_color])        # Leg color
      frame.write_byte(appearance[:feet_color])       # Feet color
      frame.write_byte(appearance[:skin_color])       # Skin color
    end

    # Writes the model animation of a context to the frame.
    # @param appearance [RuneRb::Database::Appearance] the appearance of the context whose model animation will be written to the frame.
    def write_model_animation(frame, appearance)
      frame.write_short(appearance[:stand])           # Stand Anim
      frame.write_short(appearance[:stand_turn])      # StandTurn Anim
      frame.write_short(appearance[:walk])            # Walk Anim
      frame.write_short(appearance[:turn_180])        # Turn 180
      frame.write_short(appearance[:turn_90_cw])      # Turn 90 Clockwise
      frame.write_short(appearance[:turn_90_ccw])     # Turn 90 Counter-Clockwise
      frame.write_short(appearance[:run])             # Run Anim
    end

    # Writes a chat to the frame
    # @param message [RuneRb::Entity::Message] the message to write.
    def write_chat(message)
      write_short((message.colors << 8 | message.effects), :STD, :LITTLE)
      write_byte(message.rights)
      write_byte(message.text.size, :C)
      write_reverse_bytes(message.text.reverse)
    end

    # Writes a graphic to the frame
    # @param graphic [RuneRb::Entity::Graphic] the graphic to write.
    def write_graphic(graphic)
      write_short(graphic.id)
      write_int(graphic.height << 16 | graphic.delay)
    end

    # Writes a context animation to a frame.
    # @param animation [RuneRb::Entity::Animation] the animation to write.
    def write_animation(animation)
      write_short(animation.id, :STD, :LITTLE)
      write_byte(animation.delay, :C)
    end
  end
end