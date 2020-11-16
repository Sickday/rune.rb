module RuneRb::Network::FrameWriter
  using RuneRb::Patches::ArrayOverrides
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  def write_skills(data)
    write_skill(skill_id: 0, level: data[:attack_level], experience: data[:attack_exp])
    write_skill(skill_id: 1, level: data[:defence_level], experience: data[:defence_exp])
    write_skill(skill_id: 2, level: data[:strength_level], experience: data[:strength_exp])
    write_skill(skill_id: 3, level: data[:hit_points_level], experience: data[:hit_points_exp])
    write_skill(skill_id: 4, level: data[:range_level], experience: data[:range_exp])
    write_skill(skill_id: 5, level: data[:prayer_level], experience: data[:prayer_exp])
    write_skill(skill_id: 6, level: data[:magic_level], experience: data[:magic_exp])
    write_skill(skill_id: 7, level: data[:cooking_level], experience: data[:cooking_exp])
    write_skill(skill_id: 8, level: data[:woodcutting_level], experience: data[:woodcutting_exp])
    write_skill(skill_id: 9, level: data[:fletching_level], experience: data[:fletching_exp])
    write_skill(skill_id: 10, level: data[:fishing_level], experience: data[:fishing_exp])
    write_skill(skill_id: 11, level: data[:firemaking_level], experience: data[:firemaking_exp])
    write_skill(skill_id: 12, level: data[:crafting_level], experience: data[:crafting_exp])
    write_skill(skill_id: 13, level: data[:smithing_level], experience: data[:smithing_exp])
    write_skill(skill_id: 14, level: data[:mining_level], experience: data[:mining_exp])
    write_skill(skill_id: 15, level: data[:herblore_level], experience: data[:herblore_exp])
    write_skill(skill_id: 16, level: data[:agility_level], experience: data[:agility_exp])
    write_skill(skill_id: 17, level: data[:thieving_level], experience: data[:thieving_exp])
    write_skill(skill_id: 18, level: data[:slayer_level], experience: data[:slayer_exp])
    write_skill(skill_id: 19, level: data[:farming_level], experience: data[:farming_exp])
    write_skill(skill_id: 20, level: data[:runecrafting_level], experience: data[:runecrafting_exp])
  end

  def write_skill(data)
    frame = RuneRb::Network::MetaFrame.new(134)
    frame.write_byte(data[:skill_id])
    frame.write_int(data[:experience], :STD,:MIDDLE)
    frame.write_byte(data[:level])
    write_frame(frame)
  end

  # Write all equipment data
  def write_equipment(data)
    data.each do |slot, slot_data|
      write_equipment_slot({ slot: slot,
                             item_id: slot_data == -1 ? -1 : slot_data.id,
                             item_amount: slot_data == -1 ? -1 : slot_data.size })
    end
  end

  # Write an update to equipment slot item.
  # @param data [Hash] the data that should be included in the equipment frame
  def write_equipment_slot(data)
    frame = RuneRb::Network::MetaFrame.new(34, false, true)
    frame.write_short(1688) # EquipmentForm ID
    frame.write_byte(data[:slot])
    frame.write_short(data[:item_id] + 1)
    if data[:item_amount] > 254
      frame.write_byte(255)
      frame.write_int(data[:item_amount])
    else
      frame.write_byte(data[:item_amount])
    end
    write_frame(frame)
  end

  # Write an update to inventory slot item.
  # @param data [Hash] the data to be included in the frame.
  def write_inventory(length, data)
    frame = RuneRb::Network::MetaFrame.new(53, false, true)
    frame.write_short(3214) # InventoryForm ID
    frame.write_short(length)
    data.each do |_slot_id, item_stack|
      id = item_stack.is_a?(Integer) || item_stack.nil? ? -1  : item_stack.id
      amount = item_stack.is_a?(Integer) || item_stack.nil? ? 0 : item_stack.size

      if amount > 254
        frame.write_byte(255)
        frame.write_int(amount, :STD, :INVERSE_MIDDLE)
      else
        frame.write_byte(amount)
      end

      frame.write_short(id + 1, :A, :LITTLE)
    end
    write_frame(frame)
  end

  def write_sidebars
    RuneRb::Network::SIDEBAR_INTERFACES.each do |key, value|
      write_sidebar(menu_id: key, form: value)
    end
  end

  # Write a sidebar interface
  # @param data [Hash] data for the sidebar to write. { form : Integer, menu_id: Integer }
  def write_sidebar(data)
    frame = RuneRb::Network::MetaFrame.new(71)
    frame.write_short(data[:form])
    frame.write_byte(data[:menu_id], :A)
    write_frame(frame)
  end

  # Write the region of a mob
  # @param mob [RuneRb::Entity::Mob] a hash containing x and y regional coordinates.
  def write_region(mob)
    frame = RuneRb::Network::MetaFrame.new(73)
    log "Writing [x: #{mob.position.central_region_x}, y: #{mob.position.central_region_y}]"
    frame.write_short(mob.position.central_region_x, :A)
    frame.write_short(mob.position.central_region_y)
    write_frame(frame)
  end

  # Write the login response
  # @param rights [Integer] the rights for the session logging in
  # @param flagged [Boolean] is the account flagged?
  def write_response(rights, flagged)
    frame = ''
    frame << [2].pack('c')
    frame << [rights].pack('c')
    frame << [flagged ? 1 : 0].pack('c')
    send_data(frame)
  end

  # Writes an overlay interface (on that closes when moving)
  # @param id [Integer] the ID for the interface
  def write_overlay_interface(id)
    frame = RuneRb::Network::MetaFrame.new(208)
    frame.write_short(id, :STD, :LITTLE)
    write_frame(frame)
  end

  # Writes an interface
  # @param id [Integer] the ID for the interface
  def write_interface(id)
    frame = RuneRb::Network::MetaFrame.new(97)
    frame.write_short(id)
    write_frame(frame)
  end

  # Closes open interfaces
  def write_close_interface
    frame = RuneRb::Network::MetaFrame.new(219)
    write_frame(frame)
  end

  # Writes a collection of frames that make up a post-login.
  def write_login
    write_response(@profile[:rights] >= 2 ? 2 : @profile[:rights], false)
    write_sidebars
    write_skills(@profile.stats)
    write_text('Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
    write_text('Thanks for testing Rune.rb.')
    @status[:authenticated] = :LOGGED_IN
  end

  def write_text(txt)
    frame = RuneRb::Network::MetaFrame.new(253, false, false)
    frame.write_string(txt)
    write_frame(frame)
  end

  # Write a forced disconnection.
  def write_disconnect
    @context&.logout
    frame = RuneRb::Network::MetaFrame.new(109)
    write_frame(frame)
    disconnect
  end

  def write_mock_update
    write_region(@context) if @context.flags[:region?]

    block_frame = RuneRb::Network::MetaFrame.new(-1)
    sync_frame = RuneRb::Network::MetaFrame.new(81, false, true)
    sync_frame.switch_access # Enable Bit access

    # CONTEXT MOVEMENT
    write_mob_movement(sync_frame, @context)

    # CONTEXT STATE
    # write_mob_state(block_frame, @context)
    write_entity_state(block_frame, @context)

    # UPDATE LOCAL LIST
    # TODO: impl
    sync_frame.write_bits(8, 0) # Write 8 bits holding 0 to represent the size of the local player list.
    sync_frame.write_bits(11, 2047) # Write 11 bits holding the value of 2047 to indicate no further updates are needed to local player list. This is temporary

    # LOCAL MOVEMENT
    # TODO: impl

    # ADD STATE BLOCK
    sync_frame.write_bytes(block_frame) if @context.flags[:state?]

    write_frame(sync_frame)
    @context.pulse
  end

  private

  # Writes a Mob's movement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the mob whose movement to write.
  def write_mob_movement(frame, mob)
    case mob.movement_type
    when :TELEPORT
      frame.write_bit(true)
      write_placement(frame, mob)
    when :RUN
      frame.write_bit(true)
      write_run(frame, mob)
    when :WALK
      log "Got WALK type"
      frame.write_bit(true)
      write_walk(frame, mob)
    else
      if mob.flags[:state?]
        frame.write_bit(true)
        write_stand(frame)
      else
        frame.write_bit(false)
      end
    end
  end

  # Write a placement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the mob whose placement will be written.
  def write_placement(frame, mob)
    frame.write_bits(2, 3) # Write 3 to indicate the player needs placement on a new tile.
    frame.write_bits(2, mob.position[:z]) # Write the plane. 0 being ground level
    frame.write_bit(mob.flags[:region?]) # Region change?
    frame.write_bit(mob.flags[:state?]) # Update State/Appearance?
    log "Writing [x: #{mob.position.local_x}, y: #{mob.position.local_y}]"
    frame.write_bits(7, mob.position.local_x) # Local Y
    frame.write_bits(7, mob.position.local_y) # Local X
  end

  # Writes a stand to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  def write_stand(frame)
    frame.write_bits(2, 0) # we write 0 because we're standing
  end

  # Writes a walking movement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the mob whose movement will be written
  def write_walk(frame, mob)
    frame.write_bits(2, 1) # we write 1 because we're walking
    frame.write_bits(3, mob.directions[:primary])
    frame.write_bit(mob.flags[:state?])
  end

  # Writes a running movement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the mob whose movement will be written
  def write_run(frame, mob)
    frame.write_bits(2, 2) # we write 2 because we're running
    frame.write_bits(3, mob.directions[:primary_dir])
    frame.write_bits(3, mob.directions[:secondary_dir])
    frame.write_bit(mob.flags[:state?])
  end

  def write_mob_state(frame, mob)
    # Make the mask
    mask = 0x0
    # Attributes:
    # ForcedMove
    # Graphics
    mask |= 0x100 if mob.flags[:graphic?]
    # Animation
    mask |= 0x8 if mob.flags[:animation?]
    # Forced Chat
    # Chat
    mask |= 0x80 if mob.flags[:chat?]
    # Face Entity
    # Appearance
    mask |= 0x10 if mob.flags[:state?]
    # Face Coordinates
    # Primary Hit
    # Secondary Hit
    # Append the mask
    if mask >= 0x100
      mask |= 0x40
      frame.write_short(mask, :STD, :LITTLE)
    else
      frame.write_byte(mask)
    end

    write_graphic(frame, mob) if mob.flags[:graphic?]
    write_animation(frame, mob) if mob.flags[:animation?]
    write_chat(frame, mob) if mob.flags[:chat?]
    write_appearance(frame, mob) if mob.flags[:state?]
  end

  # @param frame [RuneRb::Network::MetaFrame] the frame to write the state to.
  # @param entity [RuneRb::Entity::Context] the entity for which the state update will apply to
  def write_entity_state(frame, entity)
    # Make the mask
    mask = 0x0
    # Attributes:
    # ForcedMove
    # Graphics
    mask |= 0x100 if entity.flags[:graphic?]
    # Animation
    mask |= 0x8 if entity.flags[:animation?]
    # Forced Chat
    # Chat
    mask |= 0x80 if entity.flags[:chat?]
    # Face Entity
    # Appearance
    mask |= 0x10 if entity.flags[:state?]
    # Face Coordinates
    # Primary Hit
    # Secondary Hit
    # Append the mask
    if mask >= 0x100
      mask |= 0x40
      frame.write_short(mask, :STD, :LITTLE)
    else
      frame.write_byte(mask)
    end

    write_graphic(frame, entity) if entity.flags[:graphic?]
    write_animation(frame, entity) if entity.flags[:animation?]
    write_chat(frame, entity) if entity.flags[:chat?]
    write_appearance(frame, entity) if entity.flags[:state?]
  end


  # @param frame [RuneRb::Network::MetaFrame] the frame to write the appearance to.
  # @param mob [RuneRb::Entity::Mob] the the entity providing the appearance.
  def write_appearance(frame, mob)
    appearance_frame = RuneRb::Network::MetaFrame.new(-1)
    appearance_frame.write_byte(mob.appearance[:gender])
    appearance_frame.write_byte(mob.appearance[:head_icon])

    if mob.appearance[:mob_id] != -1
      write_morph(appearance_frame, mob)
    else
      write_equipment_block(appearance_frame, mob)
    end

    write_model_color(appearance_frame, mob)
    write_model_animation(appearance_frame, mob)

    appearance_frame.write_long(mob.profile[:name].to_base37)      # Player's name
    appearance_frame.write_byte(mob.profile.stats.combat)          # Combat Level
    appearance_frame.write_short(mob.profile.stats.total)          # Skill Level

    frame.write_byte(appearance_frame.size, :C)
    frame.write_bytes(appearance_frame)
  end

  # Writes a close of the current interface to the client.
  def write_closed_interface
    frame = RuneRb::Network::MetaFrame.new(130)
    write_frame(frame)
  end

  # Writes the model color block of the specified player
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to.
  # @param mob [RuneRb::Entity::Mob] the Mob whose model color will be written
  def write_model_color(frame, mob)
    frame.write_byte(mob.appearance[:hair_color])       # Hair color
    frame.write_byte(mob.appearance[:torso_color])      # Torso color
    frame.write_byte(mob.appearance[:leg_color])        # Leg color
    frame.write_byte(mob.appearance[:feet_color])       # Feet color
    frame.write_byte(mob.appearance[:skin_color])       # Skin color
  end

  # Writes the appearance block of the provided player
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the player whose appearance we're writing.
  def write_model_animation(frame, mob)
    frame.write_short(mob.appearance[:stand])           # Stand Anim
    frame.write_short(mob.appearance[:stand_turn])      # StandTurn Anim
    frame.write_short(mob.appearance[:walk])            # Walk Anim
    frame.write_short(mob.appearance[:turn_180])        # Turn 180
    frame.write_short(mob.appearance[:turn_90_cw])      # Turn 90 Clockwise
    frame.write_short(mob.appearance[:turn_90_ccw])     # Turn 90 Counter-Clockwise
    frame.write_short(mob.appearance[:run])             # Run Anim
  end

  # Writes the equipment block of the provided player
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param player [RuneRb::Entity::Context] the player whose equipment will be written.
  def write_equipment_block(frame, player)
    # Weapons
    (0...4).each do |itr|
      if player.equipment[itr] != -1
        frame.write_short(0x200 + player.equipment[itr].id)
      else
        frame.write_byte(0)
      end
    end

    # TORSO SLOT
    if player.equipment[4] != -1 # Item is in slot?
      frame.write_short(0x200 + player.equipment[4].id) # Write mask + item id
    else # Not wearing anything in slot?
      frame.write_short(0x100 + player.appearance[:chest]) # Write mask + chest appearance id
    end

    # SHIELD SLOT
    if player.equipment[5] != -1 # Item is in slot?
      frame.write_short(0x200 + player.equipment[5].id) # Write mask + item id
    else # Not wearing anything in slot?
      frame.write_byte(0) # Write mask + chest appearance id
    end

    # ARMS WITH PLATEBODY SUPPORT.
    if player.equipment[4] != -1
      if %w[platebody brassard leatherbody].include?(player.equipment[4].definition[:name])
        frame.write_short(0x100 + player.equipment[4].id)
      else
        frame.write_byte(0)
      end
    else
      frame.write_short(0x100 + player.appearance[:arms])
    end

    # LEGS
    if player.equipment[7] != -1
      frame.write_short(0x200 + player.equipment[7].id)
    else
      frame.write_short(0x100 + player.appearance[:legs])
    end

    # HELM
    if player.equipment[0] != -1
      if player.equipment[0].definition[:full_mask]
        frame.write_byte(0)
      else
        frame.write_short(0x100 + player.appearance[:head])
      end
    else
      frame.write_short(0x100 + player.appearance[:head])
    end

    # GLOVES
    if player.equipment[9] != -1
      frame.write_short(0x200 + player.equipment[9].id)
    else
      frame.write_short(0x100 + player.appearance[:hands])
    end

    # BOOTS
    if player.equipment[10] != -1
      frame.write_short(0x200 + player.equipment[10].id)
    else
      frame.write_short(0x100 + player.appearance[:feet])
    end

    # BEARD
    if player.equipment[0] != -1 && !player.equipment[0].definition[:show_beard] || player.appearance[:gender] == 1
      frame.write_byte(0)
    else
      frame.write_short(0x100 + player.appearance[:beard])
    end
  end

  # Writes a mob morph to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the Mob.
  def write_morph(frame, mob)
    frame.write_short(-1)
    frame.write_short(mob.appearance[:mob_id])
  end

  # Writes a chat to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the Mob.
  def write_chat(frame, mob)
    frame.write_short((mob.message[:color] << 8 | mob.message[:effects]), :STD, :LITTLE)
    frame.write_byte(mob.profile[:rights])
    frame.write_byte(mob.message[:text].size, :C)
    frame.write_reverse_bytes(mob.message[:text].reverse)
  end

  # Writes a graphic to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the Mob.
  def write_graphic(frame, mob)
    frame.write_short(mob.graphic.id)
    frame.write_int(mob.graphic.height << 16 | mob.graphic.delay)
  end

  # Writes a mob animation to a frame.
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param mob [RuneRb::Entity::Mob] the Mob.
  def write_animation(frame, mob)
    frame.write_short(mob.animation.id, :STD, :LITTLE)
    frame.write_byte(mbo.animation.delay, :C)
  end
end