module RuneRb::Network::FrameWriter
  using RuneRb::Patches::IntegerOverrides

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

  def write_text(txt)
    frame = RuneRb::Network::MetaFrame.new(253, false, true)
    frame.write_string(txt)
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
    frame = RuneRb::Network::MetaFrame.new(73)
    frame.write_short(data[:region_x] + 6, :A)
    frame.write_short(data[:region_y] + 6)
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

  def write_login
    write_response(@profile[:rights], false)
    write_sidebars
    # write_text('Thanks for testing Rune.rb.')
    #write_text('Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
    @status[:authenticated] = :LOGGED_IN
  end

  def write_mock_update
    if @context.flags[:region?]
      write_region(region_x: @context.region.region_x,
                   region_y: @context.region.region_y)
      @context.flags[:region?] = false
    end

    #block_frame = RuneRb::Network::MetaFrame.new(-1)
    sync_frame = RuneRb::Network::MetaFrame.new(81, false, true)
    sync_frame.switch_access # Enable Bit access

    # CONTEXT PLACEMENT
    # TODO: impl
    if @context.flags[:placement?] # Context player needs placement
      sync_frame.write_bit(true) # Write 1 bit to indicate placement update is required
      sync_frame.write_bits(2, 3) # Write 3 to indicate the player needs placement on a new tile.
      sync_frame.write_bits(2, 0) # Write the plane. 0 being ground level
      sync_frame.write_bit(true) # Teleporting?
      sync_frame.write_bit(false) # Update State/Appearance?
      sync_frame.write_bits(7, @context.position.local_x(@context.region)) # Local Y
      sync_frame.write_bits(7, @context.position.local_y(@context.region)) # Local X
      @context.flags[:placement?] = false # Ensure the next update frame does not require a player movement block
    elsif @context.movement[:moved?] # Context player moved
      sync_frame.write_bit(true) # Write 1 bit to indicate movement update is required
      if @context.movement[:first] != -1 && @context.movement[:second] != -1
        write_run(sync_frame, @context.movement[:first], @context.movement[:second])
      else
        write_walk(sync_frame, @context.movement[:first])
      end
    elsif @context.flags[:state?] # Context player needs a state update
      sync_frame.write_bit(true)
      write_stand(sync_frame)
    else
      sync_frame.write_bit(false) # Write 1 bit to indicate no movement update is needed at all. This is temporary
    end

    # LOCAL MOVEMENT
    # TODO: impl
    sync_frame.write_bits(8, 0) # Write 8 bits holding 0 value to indicate NO LOCAL MOVEMENT from other players. This is temporary

    # UPDATE LOCAL LIST
    # TODO: impl
    sync_frame.write_bits(11, 2047) # Write 11 bits holding the value of 2047 to indicate no further updates are needed to local player list. This is temporary

    # ADD STATE BLOCK
    # sync_frame.write_bytes(block_frame)
    write_frame(sync_frame)
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

  def write_update(context_player, local_players)
    block_frame = RuneRb::Network::MetaFrame.new(-1)
    sync_frame = RuneRb::Network::MetaFrame.new(81, false, true)
    sync_frame.switch_access # Enable Bit access

    write_context_movement(sync_frame, context_player) # Write the context player's movement
    write_entity_state(block_frame, context_player) if context_player.flags[:state][:update?] # Append the context player's state to the block frame

    sync_frame.write_bits(8, local_players.size) # Write the player list size to the sync frame
    local_players.each do |local| # Iterate through the playerlist
    write_entity_movement(payload, local) if local.flags[:moved?]
    write_entity_state(payload, local) if local.flags[:state][:update?]
    write_player_removal(payload) unless context_player.near?(local)
    end

    local_players.each do |local|
      next if local
    end
  end

  # Write a forced disconnection.
  def write_disconnect
    @context.logout if @context
    frame = RuneRb::Network::MetaFrame.new(109)
    write_frame(frame)
    disconnect
  end

  private


  # @param payload [RuneRb::Network::JOutStream] the payload to apply the removal to
  def write_player_removal(payload)
    # Inform the client
    payload.write_bit(true)
    payload.write_bits(2, 3)
  end

  # @param context [RuneRb::Entity::Context] the entity for which the movement will apply to
  # @param payload [RuneRb::Network::JOutStream] the payload to apply the movement to
  def write_context_movement(payload, context)
    # Does the context entity require a placement update
    if context.flags[:move][:update_placement]
      write_entity_placement(payload, context)
    elsif context.flags[:moved?] # Did the player move?
      write_entity_movement(payload, context)
    elsif context.flags[:state][:update?] # Does the player need a state update?
      # Write 1 bit to indicate a state update is required
      payload.write_bit(true)
      # This appends a standing movement, but indicates the client should expect a state update.
      payload.write_bits(2, 0)
    else
      # Write 1 bit to indicate no updates required.
      payload.write_bit(false)
    end
  end

  # @param entity [RuneRb::Entity::Context] the entity for which the state update will apply to
  def write_entity_state(entity)
    return unless entity.flags[:state][:update?]

    payload = RuneRb::Network::MetaFrame.new(-1)
    # Make the mask
    mask = 0x0
    # Chat updates?
    mask |= 0x80 if entity.flags[:state][:chat]
    # Appearance?
    mask |= 0x10 if entity.flags[:state][:appearance]
    # Append the mask
    if mask >= 0x100
      mask |= 0x40
      payload.write_short(mask, :STD, :LITTLE)
    else
      payload.write_byte(mask)
    end
    # Attributes:
    # Graphics
    # Animation
    # Forced Chat
    # Face Entity
    # Appearance
    # Face Coordinates
    # Primary Hit
    # Secondary Hit
    payload
  end

  # @param entity [RuneRb::Entity::Type] the entity for which the placement will occur
  # @param payload [RuneRb::Network::JOutStream] the payload which the entity placement will be written
  def write_entity_placement(payload, entity)
    # Write 1 bit to indicate placement update is required
    payload.write_bit(true)

    # This indicates the entity is being moved to a new tile (teleported?)
    payload.write_bits(2, 3)

    # Write the new placement
    payload.write_bits(2, RuneRb::Game::Map::Service.region_for(context.tile).local_tile(context.tile)[:z])
    payload.write_bit(entity.flags[:move][:reset_movement]) # Discard the movement queue?
    payload.write_bit(entity.flags[:state][:update?]) # State update required?
    payload.write_bits(7, RuneRb::Game::Map::Service.region_for(context.tile).local_tile(context.tile)[:y])
    payload.write_bits(7, RuneRb::Game::Map::Service.region_for(context.tile).local_tile(context.tile)[:x])
  end

  def write_entity_movement(payload, entity)
    return unless entity.flags[:moved?] # Ensure the entity actually moved

    # Write 1 bit to indicate a movement update will be required
    payload.write_bit(true)

    if entity.flags[:running?]
      # Write 2 bits with value of 2 to indicate the player is running
      payload.write_bits(2, 2)
      payload.write_bits(3, entity.flags[:move][:first_direction])
      payload.write_bits(3, entity.flags[:move][:second_direction])
    else
      # Write 2 bits with the value of 1 to indicate the player is walking
      payload.write_bits(2, 1)
      payload.write_bits(3, entity.flags[:move][:first_direction])
    end

    # State update required?
    payload.write_bit(entity.flags[:state][:update?])
  end

  def write_chat(player, out)
    out.write_short(player)
  end

  def cached_update(client)
    movement_payload = movement_for(client)
    state_payload = RuneRb::Network::JOutStream.new(client.cipher)

    movement_payload.start_header(81)
    out.switch_access # Bit access

    movement_update(client, out)
    out.write_bits(1, 0)
    state_update(client, block) if client.update

    out.write_bits(8, 0) # PlayerList Size
    ##
    # player_list.each do |entity|
    #   if (client.tile.near? entity.tile) &&
    #       entity.active? && !entity.leaving
    #     movement_update_other(entity, out)
    #     state_update(entity, block)
    #   else
    #       out.write_bit(true)
    #       out.write_bits(2, 3)
    #
    #   end
    # end
    #
    # b8192: update entity list
    out.write_bits(11, 2047) if block.size > 0
    out.switch_access
    out.write_bytes(block.build.bytes)
    out.finish_header(true, true)
    puts "Generated update:\t#{out}"
    out
  end

  def movement_update(client, out)
    if client.region_changed
      out.write_bit(true)
      push_placement(client, out)
    else
      if client.update
        out.write_bit(true)
        push_stand(out)
      else
        out.write_bit(false)
      end
    end

  end

  def push_placement(buffer)
    buffer.write_bits(2, 3)
    buffer.write_bits(2, client.tile[:z])
    buffer.write_bit(client.reset) # Reset entity movement
    buffer.write_bit(client.update) # Update the entity's attributes
    buffer.write_bits(7, client.tile[:y])
    buffer.write_bits(7, client.tile[:x])
    @region_changed = false
  end

  # Pushes a standing section. The client expects an attribute section after this.
  def push_stand(buffer)
    buffer.write_bits(2, 0)
  end
end