module RuneRb::Network::FrameWriter
  using RuneRb::Patches::ArrayOverrides
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  def write_skills(data)
    data[:skill_data].each do |id, skill_data|
      write_skill({ skill_id: id, experience: skill_data[:experience], level: skill_data[:level] })
    end
  end

  def write_skill(data)
    frame = RuneRb::Network::Frame.new(134)
    frame.write_byte(data[:skill_id])
    frame.write_byte(data[:level])
    frame.write_int(data[:experience], :MIDDLE)
    write_frame(frame)
  end

  # Write all equipment data
  def write_equipment(data)
    data[:equipment_data].each do |slot, slot_data|
      write_equipment_slot({ slot: slot, item_id: slot_data[:id], item_amount: slot_data[:amount] })
    end
  end

  # Write an update to equipment slot item.
  # @param data [Hash] the data that should be included in the equipment frame
  def write_equipment_slot(data)
    frame = RuneRb::Network::MetaFrame.new(34, false,true)
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
      id = item_stack&.id.nil? ? -1 : item_stack.id
      amount = item_stack&.size.nil? ? 0 : item_stack.size

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
    write_response(@profile[:rights], false)
    write_sidebars
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
    write_context_movement(sync_frame)

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

  def write_context_movement(frame)
    if @context.flags[:teleport?] || @context.flags[:region?]
      to = @context.movement[:teleport][:to]
      frame.write_bit(true) # Write 1 bit to indicate movement occurred
      frame.write_bits(2, 3) # Write 3 to indicate the player needs placement on a new tile.
      frame.write_bits(2, @context.position[:z]) # Write the plane. 0 being ground level
      frame.write_bit(@context.flags[:teleport?]) # Teleporting?
      frame.write_bit(@context.flags[:state?]) # Update State/Appearance?
      frame.write_bits(7, to.local_x(@context.position)) # Local Y
      frame.write_bits(7, to.local_y(@context.position)) # Local X
    elsif @context.movement[:walk] != -1 # Context player walked
      log RuneRb::COL.magenta('Player Walked')
      frame.write_bit(true) # Write 1 bit to indicate movement occurred
      if @context.movement[:run] != -1
        write_run(frame, @context.movement[:walk], @context.movement[:run]) # Write the running bits
      else
        write_walk(frame, @context.movement[:walk]) # Write walking bits
      end
      frame.write_bit(@context.flags[:state?]) # 1 or 0 depending on if a state update is required
    elsif @context.flags[:state?] # No movement occurred. State update required?
      frame.write_bit(true) # Write 1 bit to indicate a state update is required
      write_stand(frame) # Write standing bit
    else # No movement or state required
      frame.write_bit(false) # DO NOTHING?!
    end
  end

  # Writes a walking movement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  def write_walk(frame, direction)
    frame.write_bits(2, 1) # we write 1 because we're walking
    frame.write_bits(3, direction)
  end

  # Writes a running movement to a frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  def write_run(frame, first_direction, second_direction)
    frame.write_bits(2, 2) # we write 2 because we're running
    frame.write_bits(3, first_direction)
    frame.write_bits(3, second_direction)
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
    # Animation
    # Forced Chat
    # Chat
    mask |= 0x80 if entity.flags[:chat]
    # Face Entity
    # Appearance
    mask |= 0x10 if entity.flags[:appearance]
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

    write_appearance(frame, entity) if entity.flags[:appearance]
    write_chat(frame, entity) if entity.flags[:chat]
  end

  # @param frame [RuneRb::Network::MetaFrame] the frame to write the appearance to.
  # @param entity [RuneRb::Entity::Type] the the entity providing the appearance.
  def write_appearance(frame, entity)
    appearance_frame = RuneRb::Network::MetaFrame.new(-1)
    appearance_frame.write_byte(entity.appearance[:gender])
    if entity.appearance[:head_icon] >= 8 || entity.appearance[:head_icon] <= -1
      appearance_frame.write_byte(entity.appearance[:head_icon])
    else
      appearance_frame.write_byte(0) # Head Icon
    end

    if entity.appearance[:mob_id] != -1
      appearance_frame.write_byte(255)
      appearance_frame.write_byte(255)
      appearance_frame.write_short(entity.appearance[:mob_id])
    else
      ## UNARMED TEMPORARY
      4.times { appearance_frame.write_byte(0) }                # EQ Slots 1-4
      appearance_frame.write_short(0x100 + entity.appearance[:chest]) # Chest
      appearance_frame.write_byte(0)                            # Shield
      appearance_frame.write_short(0x100 + entity.appearance[:arms])  # Arms
      appearance_frame.write_short(0x100 + entity.appearance[:legs])  # Legs
      appearance_frame.write_short(0x100 + entity.appearance[:head])  # Head
      appearance_frame.write_short(0x100 + entity.appearance[:hands]) # Hands
      appearance_frame.write_short(0x100 + entity.appearance[:feet])  # Feet
      entity.appearance[:gender] == 0 ? appearance_frame.write_short(0x100 + entity.appearance[:beard]) : appearance_frame.write_byte(0) # Beard
    end

    appearance_frame.write_byte(entity.appearance[:hair_color])       # Hair color
    appearance_frame.write_byte(entity.appearance[:torso_color])      # Torso color
    appearance_frame.write_byte(entity.appearance[:leg_color])        # Leg color
    appearance_frame.write_byte(entity.appearance[:feet_color])       # Feet color
    appearance_frame.write_byte(entity.appearance[:skin_color])       # Skin color

    appearance_frame.write_short(entity.appearance[:stand])           # Stand Anim
    appearance_frame.write_short(entity.appearance[:stand_turn])      # StandTurn Anim
    appearance_frame.write_short(entity.appearance[:walk])            # Walk Anim
    appearance_frame.write_short(entity.appearance[:turn_180])        # Turn 180
    appearance_frame.write_short(entity.appearance[:turn_90_cw])      # Turn 90 Clockwise
    appearance_frame.write_short(entity.appearance[:turn_90_ccw])     # Turn 90 Counter-Clockwise
    appearance_frame.write_short(entity.appearance[:run])             # Run Anim

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

  # Writes a chat frame
  # @param frame [RuneRb::Network::MetaFrame] the frame to write to
  # @param player [RuneRb::Entity::Context] the player.
  def write_chat(frame, player)
    message = player.messages[:current]
    frame.write_short((message[:color] << 8 | message[:effects]), :STD, :LITTLE)
    frame.write_byte(player.profile[:rights])
    frame.write_byte(message[:text].size, :C)
    frame.write_reverse_bytes(message[:text].reverse)
    player.messages[:last] = message
  end
end