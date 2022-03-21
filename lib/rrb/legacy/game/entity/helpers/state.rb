module RuneRb::Game::Entity::Helpers::State
  # @!attribute [r] flags
  # @return [Hash] a map of key value pairs
  attr :flags

  # @!attribute [r] state
  # @return [ContextStateBlock] the state block for the context
  attr :state

  # Is a state update required?
  # @return [Boolean]
  def state_update?
    @flags[:chat?] || @flags[:graphic?] || @flags[:animation?] || looks_update?
  end

  # Is a looks update required?
  # @return [Boolean]
  def looks_update?
    @flags[:looks?]
  end

  private

  # Generate a buffer containing data related to the Context#appearance
  def generate_looks
    @state.looks_buffer = RuneRb::IO::Buffer.new('w')

    # Gender
    @state.looks_buffer.write(@profile.appearance.gender, type: :byte)

    # HeadIcon
    @state.looks_buffer.write(@profile.appearance.head_icon, type: :byte)

    # Write the appearance normally if there is no morphing.
    if @profile.appearance.mob_id == -1
      write_equipment
      write_model_color
      write_model_animation
    else
      # Else write the morph
      write_morph
    end

    # Player's name
    @state.looks_buffer.write(@session.handshake[:name_hash], type: :long)

    # Combat Level
    @state.looks_buffer.write(126, type: :byte)# profile.skills.combat_level, type: :byte)

    # Skill Level
    @state.looks_buffer.write(@profile.skills[:total_level], type: :short)
  end

  # Generate a buffer containing data related to aspects of the player's state such as current graphics, animation, chat, and looks.
  def generate_state
    @state.state_buffer = RuneRb::IO::Buffer.new('w')
    write_mask
    write_graphic if @flags[:graphic?]
    write_animation if @flags[:animation?]
    write_chat if @flags[:chat?]
    write_looks if @flags[:looks?]
  end

  # Initializes and sets the state of required update flags.
  def load_state
    @flags ||= {}
    @flags[:looks?] = true
    @flags[:region?] = true
    @flags[:teleport?] = true
    @state = StateBlock.new(nil, nil, 0)
  end

  # Resets the update flags for the Mob.
  def reset_flags
    @flags[:chat?] = false
    @flags[:graphic?] = false
    @flags[:animation?] = false
    @flags[:looks?] = false
    @flags[:region?] = false
    @flags[:forced_chat?] = false
    @flags[:teleport?] = false
    @flags[:moved?] = false
  end

  # A block of data containing the state buffer, looks buffer and mask.
  # @param state_buffer [RuneRb::IO::Buffer] the state buffer
  # @param looks_buffer [RuneRb::IO::Buffer] the looks buffer
  # @param mask [Integer] the mask
  StateBlock = Struct.new(:state_buffer, :looks_buffer, :mask)

  def write_looks
    # Writing the looks buffer size and payload to the state buffer.
    @state.state_buffer.write(@state.looks_buffer.length, type: :byte, mutation: :NEG)
    @state.state_buffer.write(@state.looks_buffer, type: :bytes)
  end

  def write_mask
    # Attributes:
    # ForcedMove
    @state.mask |= 0x400 if @flags[:force_move?]
    # Graphics
    @state.mask |= 0x100 if @flags[:graphic?]
    # Animation
    @state.mask |= 0x8 if @flags[:animation?]
    # Forced Chat
    @state.mask |= 0x4 if @flags[:force_chat?]
    # Chat
    @state.mask |= 0x80 if @flags[:chat?]
    # Face Entity
    @state.mask |= 0x1 if @flags[:face_mob?]
    # Appearance
    @state.mask |= 0x10 if @flags[:looks?]
    # Face Coordinates
    @state.mask |= 0x2 if @flags[:turn_to?]
    # Primary Hit
    @state.mask |= 0x20 if @flags[:primary_hit?]
    # Secondary Hit
    @state.mask |= 0x200 if @flags[:secondary_hit?]
    # Append the mask
    if @state.mask >= 0x100
      @state.mask |= 0x40
      @state.state_buffer.write(@state.mask, type: :short, order: :LITTLE)
    else
      @state.state_buffer.write(@state.mask, type: :byte)
    end
  end

  # Writes the equipment of a context to the buffer.
  def write_equipment

    # HAT SLOT
    if @equipment[:HAT].id != -1
      @state.looks_buffer.write(0x200 + @equipment[:HAT].id, type: :short, mutation: :STD, order: :BIG)
    else
      @state.looks_buffer.write(0, type: :byte)
    end

    # CAPE SLOT
    if @equipment[:CAPE].id != -1
      @state.looks_buffer.write(0x200 + @equipment[:CAPE].id, type: :short, mutation: :STD, order: :BIG)
    else
      @state.looks_buffer.write(0, type: :byte)
    end

    # AMULET SLOT
    if @equipment[:AMULET].id != -1
      @state.looks_buffer.write(0x200 + @equipment[:AMULET].id, type: :short)
    else
      @state.looks_buffer.write(0, type: :byte)
    end

    # WEAPON SLOT
    if @equipment[:WEAPON].id != -1
      @state.looks_buffer.write(0x200 + @equipment[:WEAPON].id, type: :short)
    else
      @state.looks_buffer.write(0, type: :byte)
    end

    # CHEST SLOT
    if @equipment[:CHEST].id != -1 # Item is in slot?
      @state.looks_buffer.write(0x200 + @equipment[:CHEST].id, type: :short) # Write mask + item id
    else # Not wearing anything in slot?
      @state.looks_buffer.write(0x100 + @profile.appearance.chest, type: :short) # Write mask + chest appearance id
    end

    # SHIELD SLOT
    if @equipment[:SHIELD].id != -1 # Item is in slot?
      @state.looks_buffer.write(0x200 + @equipment[:SHIELD].id, type: :short) # Write mask + item id
    else # Not wearing anything in slot?
      @state.looks_buffer.write(0, type: :byte) # Write mask + chest appearance id
    end

    # ARMS WITH PLATEBODY SUPPORT.
    if @equipment[:CHEST].id != -1
      if %w[platebody brassard leatherbody].any? { |type| @equipment[:CHEST].definition.name.include?(type) }
        @state.looks_buffer.write(0x200, type: :byte)
      else
        @state.looks_buffer.write(0x100 + @profile.appearance.arms, type: :short)
      end
    else
      @state.looks_buffer.write(0x100 + @profile.appearance.arms, type: :short)
    end

    # LEGS
    if @equipment[:LEGS].id != -1
      @state.looks_buffer.write(0x200 + @equipment[:LEGS].id, type: :short)
    else
      @state.looks_buffer.write(0x100 + @profile.appearance.legs, type: :short)
    end

    # HELM
    if @equipment[:HAT].id != -1 && @equipment[:HAT].definition[:full_mask]
      @state.looks_buffer.write(0, type: :byte)
    else
      @state.looks_buffer.write(0x100 + @profile.appearance.head, type: :short)
    end

    # GLOVES
    if @equipment[:GLOVES].id != -1
      @state.looks_buffer.write(0x200 + @equipment[:GLOVES].id, type: :short)
    else
      @state.looks_buffer.write(0x100 + @profile.appearance.hands, type: :short)
    end

    # BOOTS
    if @equipment[:BOOTS].id != -1
      @state.looks_buffer.write(0x200 + @equipment[:BOOTS].id, type: :short)
    else
      @state.looks_buffer.write(0x100 + @profile.appearance.feet, type: :short)
    end

    # BEARD
    if (@equipment[:HAT].id != -1) && (@profile.appearance.gender == 1 || @equipment[:HAT].definition[:full_mask])
      @state.looks_buffer.write(0, type: :byte)
    else
      @state.looks_buffer.write(0x100 + @profile.appearance.beard, type: :short)
    end
  rescue StandardError => e
    err 'An error occurred while writing equipment!', e.message
    err e.backtrace&.join("\n")
  end

  # Writes the model animation of a context to the buffer.
  def write_model_animation
    @state.looks_buffer.write(@profile.appearance.stand_emote, type: :short)           # Stand Anim
    @state.looks_buffer.write(@profile.appearance.stand_turn_emote, type: :short)      # StandTurn Anim
    @state.looks_buffer.write(@profile.appearance.walk_emote, type: :short)            # Walk Anim
    @state.looks_buffer.write(@profile.appearance.turn_180_emote, type: :short)        # Turn 180
    @state.looks_buffer.write(@profile.appearance.turn_90_cw_emote, type: :short)      # Turn 90 Clockwise
    @state.looks_buffer.write(@profile.appearance.turn_90_ccw_emote, type: :short)     # Turn 90 Counter-Clockwise
    @state.looks_buffer.write(@profile.appearance.run_emote, type: :short)             # Run Anim
  end

  # Writes the model color of a context to the buffer.
  def write_model_color
    @state.looks_buffer.write(@profile.appearance.hair_color, type: :byte)       # Hair color
    @state.looks_buffer.write(@profile.appearance.torso_color, type: :byte)      # Torso color
    @state.looks_buffer.write(@profile.appearance.leg_color, type: :byte)        # Leg color
    @state.looks_buffer.write(@profile.appearance.feet_color, type: :byte)       # Feet color
    @state.looks_buffer.write(@profile.appearance.skin_color, type: :byte)       # Skin color
  end

  # Writes the mob morphing bytes of a context to the message
  def write_morph
    @state.looks_buffer.write(0xFF, type: :byte)
    @state.looks_buffer.write(0xFF, type: :byte)
    @state.looks_buffer.write(@profile.appearance.mob_id, type: :short, mutation: :STD, order: :BIG)
  end

  # Writes a graphic to the state block
  def write_graphic
    @state.state_buffer.write(@graphic.id, type: :short)
    @state.state_buffer.write((@graphic.height << 16 | @graphic.delay), type: :int)
  end

  # Writes a context animation to a message.
  def write_animation
    @state.state_buffer.write(@animation.id, type: :short, order: :LITTLE)
    @state.state_buffer.write(@animation.delay, type: :byte, mutation: :NEG)
  end

  # Writes a chat to the message
  def write_chat
    @state.state_buffer.write((@chat_message.colors << 8 | @chat_message.effects), type: :short, order: :LITTLE)
    @state.state_buffer.write(@profile.attributes.rights, type: :byte)
    @state.state_buffer.write(@chat_message.text.size, type: :byte, mutation: :NEG)
    @state.state_buffer.write(@chat_message.text.reverse, type: :reverse_bytes)
  end
end
