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

  # Write the region
  # @param data [Hash] a hash containing x and y regional coordinates.
  def write_region(data)
    log "Writing region #{data.inspect}" if RuneRb::DEBUG
    frame = RuneRb::Network::MetaFrame.new(73)
    frame.write_short(data[:region_x] + 6, :A)
    frame.write_short(data[:region_y] + 6)
    write_frame(frame)
    @context.flags[:region?] = false if @context
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

  def write_login
    write_response(@profile[:rights] >= 2 ? 2 : @profile[:rights], false)
    write_sidebars
    write_skills(@profile.stats)
    write_text('Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
    write_text('Thanks for testing Rune.rb.')
    write_region(region_x: @profile.location.position.region_x,
                 region_y: @profile.location.position.region_y)
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
    if @context.flags[:region?]
      write_region(region_x: @context.profile.location.position.region_x,
                   region_y: @context.profile.location.position.region_y)
    end

    block_frame = RuneRb::Network::MetaFrame.new(-1)
    sync_frame = RuneRb::Network::MetaFrame.new(81, false, true)
    sync_frame.switch_access # Enable Bit access

    # CONTEXT MOVEMENT
    write_entity_movement(sync_frame, @context)

    # CONTEXT STATE
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
  end

  private

  def write_entity_movement(frame, context)
    if context.flags[:teleport?] || context.flags[:region?]
      frame.write_bit(true) # Write 1 bit to indicate movement occurred
      write_placement(frame, context)
    elsif context.movement[:primary_dir] != -1 # Context player walked
      log RuneRb::COL.magenta('Player Walked')
      frame.write_bit(true) # Write 1 bit to indicate movement occurred
      if context.movement[:secondary_dir] != -1
        write_run(frame, context) # Write the running bits
      else
        write_walk(frame, context.movement[:walk]) # Write walking bits
      end
      frame.write_bit(context.flags[:state?]) # 1 or 0 depending on if a state update is required
    elsif context.flags[:state?] # No movement occurred. State update required?
      frame.write_bit(true) # Write 1 bit to indicate a state update is required
      write_stand(frame) # Write standing bit
    else # No movement or state required
      frame.write_bit(false) # DO NOTHING?!
    end
  end

  # Write a placement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param entity [RuneRb::Entity::Type] the entity whose placement we're writing.
  def write_placement(frame, entity)
    frame.write_bits(2, 3) # Write 3 to indicate the player needs placement on a new tile.
    frame.write_bits(2, entity.position[:z]) # Write the plane. 0 being ground level
    frame.write_bit(entity.flags[:teleport?]) # Teleporting?
    frame.write_bit(entity.flags[:state?]) # Update State/Appearance?
    frame.write_bits(7, entity.position.local_x) # Local Y
    frame.write_bits(7, entity.position.local_y) # Local X
  end

  # Writes a running movement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  def write_run(frame, entity)
    frame.write_bits(2, 2) # we write 2 because we're running
    frame.write_bits(3, entity.movement[:primary_dir])
    frame.write_bits(3, entity.movement[:secondary_dir])
  end

  # Writes a walking movement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  def write_walk(frame, direction)
    frame.write_bits(2, 1) # we write 1 because we're walking
    frame.write_bits(3, direction)
  end

  # Writes a stand to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  def write_stand(frame)
    frame.write_bits(2, 0) # we write 0 because we're standing
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
  # @param entity [RuneRb::Entity::Type] the the entity providing the appearance.
  def write_appearance(frame, entity)
    appearance_frame = RuneRb::Network::MetaFrame.new(-1)
    appearance_frame.write_byte(entity.appearance[:gender])
    appearance_frame.write_byte(entity.appearance[:head_icon])

    if entity.appearance[:mob_id] != -1
      write_morph(appearance_frame, entity)
    else
      write_equipment_block(appearance_frame, entity)
    end

    write_model_color(appearance_frame, entity)
    write_model_animation(appearance_frame, entity)

    appearance_frame.write_long(entity.profile[:name].to_base37)      # Player's name
    appearance_frame.write_byte(entity.profile.stats.combat)          # Combat Level
    appearance_frame.write_short(entity.profile.stats.total)          # Skill Level

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
  # @param player [RuneRb::Entity::Context] the player whose model color will be written
  def write_model_color(frame, player)
    frame.write_byte(player.appearance[:hair_color])       # Hair color
    frame.write_byte(player.appearance[:torso_color])      # Torso color
    frame.write_byte(player.appearance[:leg_color])        # Leg color
    frame.write_byte(player.appearance[:feet_color])       # Feet color
    frame.write_byte(player.appearance[:skin_color])       # Skin color
  end

  # Writes the appearance block of the provided player
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param player [RuneRb::Entity::Context] the player whose appearance we're writing.
  def write_model_animation(frame, player)
    frame.write_short(player.appearance[:stand])           # Stand Anim
    frame.write_short(player.appearance[:stand_turn])      # StandTurn Anim
    frame.write_short(player.appearance[:walk])            # Walk Anim
    frame.write_short(player.appearance[:turn_180])        # Turn 180
    frame.write_short(player.appearance[:turn_90_cw])      # Turn 90 Clockwise
    frame.write_short(player.appearance[:turn_90_ccw])     # Turn 90 Counter-Clockwise
    frame.write_short(player.appearance[:run])             # Run Anim
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
  # @param player [RuneRb::Entity::Type] the player.
  def write_morph(frame, player)
    frame.write_short(-1)
    frame.write_short(player.appearance[:mob_id])
  end

  # Writes a chat to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param player [RuneRb::Entity::Context] the player.
  def write_chat(frame, player)
    frame.write_short((player.message[:color] << 8 | player.message[:effects]), :STD, :LITTLE)
    frame.write_byte(player.profile[:rights])
    frame.write_byte(player.message[:text].size, :C)
    frame.write_reverse_bytes(player.message[:text].reverse)
  end

  # Writes a graphic to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param player [RuneRb::Entity::Context] the player.
  def write_graphic(frame, player)
    frame.write_short(player.graphic.id)
    frame.write_int(player.graphic.height << 16 | player.graphic.delay)
  end

  # Writes a animation to a frame.
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param player [RuneRb::Entity::Context] the player.
  def write_animation(frame, player)
    frame.write_short(player.animation.id, :STD, :LITTLE)
    frame.write_byte(player.animation.delay, :C)
  end
end