module RuneRb::Network::FrameWriter
  using RuneRb::Patches::IntegerOverrides

  # Encodes a frame using the Peer#cipher.
  # @param frame [RuneRb::Network::Frame] the frame to encode.
  def encode_frame(frame)
    raise 'Invalid cipher for client!' unless @cipher

    frame.header[:op_code] += @cipher[:encryptor].next_value.unsigned(:byte)
    frame
  end

  def write_skills(data)
    data[:skill_data].each do |id, skill_data|
      write_skill({ skill_id: id, experience: skill_data[:experience], level: skill_data[:level] })
    end
  end

  def write_skill(data)
    frame = RuneRb::Network::Frame.new
    header = RuneRb::Network::FrameHeader.new(134)
    payload = RuneRb::Network::JWriteBuffer.new
    payload.write_byte(data[:skill_id])
    payload.write_byte(data[:level])
    payload.write_int(data[:experience], :MIDDLE)
    out.finish_header(false, false)
    @channel[:out] << out.flush
  end

  def write_equipment(data)
    data[:equipment_data].each do |slot, slot_data|
      write_equipment_slot({ slot: slot, item_id: slot_data[:id], item_amount: slot_data[:amount] })
    end
  end

  def write_equipment_slot(data)
    out.start_header(34)
    out.write_short(1688) # Equipment interface ID?
    out.write_byte(data[:slot])
    out.write_short(data[:item_id] + 1)
    if data[:item_amount] > 254
      out.write_byte(255)
      out.write_short(data[:item_amount])
    else
      out.write_byte(data[:item_amount])
    end
    out.finish_header(true, true)
    @channel[:out] << out.flush
  end

  def write_inventory(data)
    out.start_header(53)
    out.write_short(3214) # Inventory interface ID?
    out.write_short(data[:inventory_length])
    out.write_short(data[:inventory_size])
    data[:inventory_data].each do |_id, slot_stack|
      # Write the stack amount first
      if slot_stack[-1] > 254
        out.write_byte(255)
        out.write_int(slot_stack[-1], :STD, :INVERSE_MIDDLE)
      else
        out.write_byte(slot_stack[-1])
      end
      # Write the stack id next
      out.write_short(slot_stack[0] + 1, :A, :LITTLE)
    end
  end

  def write_text(txt)
    out = RuneRb::Network::JOutStream.new(@cipher)
    out.start_header(253)
    out.write_string(txt)
    out.finish_header(true, true)
    @channel[:out] << out.flush
  end

  def write_sidebars
    RuneRb::Network::SIDEBAR_INTERFACES.each { |menu_id, form_id| write_sidebar({ menu_id: menu_id, form: form_id }) }
  end

  def write_sidebar(data)
    out = RuneRb::Network::JOutStream.new(@cipher)
    out.start_header(71)
    out.write_short(data[:form])
    out.write_byte(data[:menu_id], :A)
    out.finish_header(false, false)
    @channel[:out] << out.flush
  end

  # Write the region
  # @param data [Hash] a hash containing x and y regional coordinates.
  def write_region(data)
    out = RuneRb::Network::JOutStream.new(@cipher)
    out.start_header(73)
    out.write_short((data[:region_x] / 8) + 6, :A)
    out.write_short((data[:region_y] / 8) + 6)
    out.finish_header(false, false)
    @channel[:out] << out.flush
  end

  def write_update(context_player, local_players, indicies)
    block_frame = RuneRb::Network::JOutStream.new(@cipher)
    sync_frame = RuneRb::Network::JOutStream.new(@cipher)
    sync_frame.start_header(81) # Write the frame header
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
    out = RuneRb::Network::JOutStream.new(@cipher)
    out.start_header(109)
    out.finish_header(false)
    @channel[:out] << out.flush
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
  # @param payload [RuneRb::Network::JOutStream] the payload which the state will be appended to
  def write_entity_state(payload, entity)
    return unless entity.flags[:state][:update?]

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