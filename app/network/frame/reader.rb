module RuneRb::Network::FrameReader
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  private

  # Parses the next readable frame
  def next_frame
    @current = RuneRb::Network::InFrame.new(@in.next_byte)
    @current = decode_frame(@current)
    @current.header[:length] = @in.next_byte if @current.header[:length] == -1
    @current.header[:length].times { @current.push(@in.slice!(0)) }
    handle_frame(@current)
  end

  # Processes the frame parameter
  # @param frame [RuneRb::Network::InFrame] the frame to handle
  def handle_frame(frame)
    case frame.header[:op_code]
    when 0
      log 'Received Heartbeat!' if RuneRb::DEBUG
    when 3 # Window Focus
      focused = frame.read_byte(false)
      log RuneRb::COL.blue("Client Focus: #{RuneRb::COL.cyan(focused.positive? ? '[Focused]' : '[Unfocused]')}!") if RuneRb::DEBUG
    when 4
      @context.schedule(:chat,
                        effects: frame.read_byte(false, :S),
                        color: frame.read_byte(false, :S),
                        message: frame.read_bytes_reverse(frame.header[:length] - 2, :A))
    when 41 # TODO: Parse EquipItem frame
      item_id = frame.read_short(false)
      slot = frame.read_short(false, :A)
      interface_id = frame.read_short(false)
    when 77, 78, 165, 189, 210, 226, 121 # Ping frame
      log "Got ping frame #{frame.header[:op_code]}" if RuneRb::DEBUG
    when 86
      roll = frame.read_short(false, :STD, :LITTLE)
      yaw = frame.read_short(false, :STD, :LITTLE)
      log "Camera Rotation: [Roll]: #{roll} || [Yaw]: #{yaw}" if RuneRb::DEBUG
    when 103 # TODO: Parse Command frame
      command = frame.read_string
    when 145 # Remove item in slot
      interface_id = frame.read_short(false, :A)
      slot = frame.read_short(false, :A)
      item_id = frame.read_short(false, :A)
      # TODO: Parse RemoveItemInSlot frame
    when 185
      id = frame.read_short
      parse_button(id)
      log "Got button ID #{id}" if RuneRb::DEBUG
    when 202
      log 'Received Idle Frame!' if RuneRb::DEBUG
    when 214
      interface_id = frame.read_short(false, :A, :LITTLE)
      _inserting = frame.read_byte(false, :C) # This will matter when bank is implemented. TODO: impl bank
      old_slot = frame.read_short(false, :A, :LITTLE)
      new_slot = frame.read_short(false, :STD, :LITTLE)
      case interface_id
      when 3214
        if old_slot >= 0 &&
           new_slot >= 0 &&
           old_slot <= @context.inventory.capacity &&
           new_slot <= @context.inventory.capacity
          @context.inventory.swap(old_slot, new_slot)
        end
      else
        err "Unrecognized Interface ID: #{interface_id} for SwitchItemFrame"
        return
      end
    when 241 # Mouse Click
      value = frame.read_int(false)
      delay = (value >> 20) * 50

      right = (value >> 19 & 0x1) == 1

      coords = value & 0x3FFFF
      x = coords % 765
      y = coords / 765

      if RuneRb::DEBUG
        log RuneRb::COL.blue((right ? 'Right' : 'Left') + "Mouse Click at #{RuneRb::COL.cyan("Position: x: #{x}, y: #{y}, delay: #{delay}")}")
      end
    when 248, 164, 98 # Movement
      log "Received movement packet: #{frame.header[:op_code]}" if RuneRb::DEBUG
      length = frame.header[:length]
      length -= 14 if frame.header[:op_code] == 248

      steps = (length - 5) / 2
      path = Array.new(steps, Array.new(2))
      first_x = frame.read_short(false, :A, :LITTLE)

      steps.times do |step|
        path[step][0] = frame.read_byte(false)
        path[step][1] = frame.read_byte(false)
      end

      first_y = frame.read_short(false, :STD, :LITTLE)

      @context.movement[:handler].reset
      @context.movement[:handler].running = frame.read_byte(false, :C) == 1
      @context.movement[:handler].push_position(RuneRb::Game::Map::Position.new(first_x, first_y))

      steps.times do |step|
        path[step][0] += first_x
        path[step][1] += first_y
        @context.movement[:handler].push_position(RuneRb::Game::Map::Position.new(path[step][0], path[step][1]))
      end
    else
      err "Unhandled frame: #{frame.inspect}"
    end
    # Parse the next frame if there's still data in the buffer.
    next_frame if @in.size >= 3
  end

  def parse_button(id)
    case id
    when 2458 then write_disconnect if @status[:authenticated] == :LOGGED_IN
    else err "Unhandled button! ID: #{id}"
    end
  end
end