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
                        text: frame.read_bytes_reverse(frame.header[:length] - 2, :A))
    when 41 # FIRST CLICK ON ITEM. Parse by interface id.
      item_id = frame.read_short(false)
      slot = frame.read_short(false, :A)  + 1 # This is the Slot that was clicked.
      _interface_id = frame.read_short(false, :A)
      log "Got equip [slot]: #{slot} || [item]: #{item_id} "
      item = @context.inventory.at(slot)
      @context.equipment[item.definition[:slot]] = item
      @context.inventory.remove(item.id)
      @context.schedule(:equipment)
      @context.schedule(:inventory)
    when 77, 78, 165, 189, 210, 226, 121 # Ping frame
      log "Got ping frame #{frame.header[:op_code]}" if RuneRb::DEBUG
    when 86
      roll = frame.read_short(false, :STD, :LITTLE)
      yaw = frame.read_short(false, :STD, :LITTLE)
      log "Camera Rotation: [Roll]: #{roll} || [Yaw]: #{yaw}" if RuneRb::DEBUG
    when 87 # 5th option. currently parsed as an inventory item drop even if it isn't...
      RuneRb::Game::Item::Click.parse_option(:fifth_click, { context: @context, frame: frame })
    when 103
      parse_cmd_string(frame.read_string)
    when 145 # Remove item in slot
      RuneRb::Game::Item::Click.parse_action(:first_item, { context: @context, frame: frame })
    when 185
      id = frame.read_short
      parse_button(id)
      log "Got button ID #{id}" if RuneRb::DEBUG
    when 202
      log 'Received Idle Frame!' if RuneRb::DEBUG
    when 214
      RuneRb::Game::Item::Click.parse_action(:switch_item, { context: @context, frame: frame })
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

  def parse_cmd_string(string)
    pcs = string.split(' ')
    case pcs[0]
    when 'anim'
      @context.schedule(:animation, animation: RuneRb::Game::Animation.new(pcs[0].to_i, pcs[1].to_i || 0))
    when 'gfx'
      @context.schedule(:graphic, graphic: RuneRb::Game::Graphic.new(pcs[0].to_i, pcs[1].to_i || 100, pcs[2].to_i || 0))
    when 'item'
      stack = RuneRb::Game::Stack.new(pcs[1].to_i)
      if stack.definition[:stackable]
        stack.size = pcs[2].to_i
        @context.inventory.add(stack)
        log RuneRb::COL.green("Adding #{stack.definition[:name]} x #{stack.size}") if RuneRb::DEBUG
      else
        pcs[2].to_i.times do
          @context.inventory.add(stack)
          log RuneRb::COL.green("Adding #{stack.definition[:name]} x #{stack.size}") if RuneRb::DEBUG
        end
      end
      @context.schedule(:inventory)
    when 'to'
      log RuneRb::COL.green("Moving #{@context.profile[:name]} to #{pcs[1]}, #{pcs[2]}") if RuneRb::DEBUG
      @context.schedule(:teleport, location: RuneRb::Game::Map::Position.new(pcs[1].to_i,
                                                                             pcs[2].to_i,
                                                                             pcs[3].to_i || 0))
    when 'mob'
      log RuneRb::COL.green("Morphing into mob: #{pcs[1]}") if RuneRb::DEBUG
      @context.schedule(:mob, mob_id: pcs[1].to_i)
    when 'overhead'
      if pcs[1].to_i <= 7 && pcs[1].to_i >= -1
        log RuneRb::COL.green("Changing HeadIcon to #{pcs[1]}") if RuneRb::DEBUG
        @context.schedule(:head, head_icon: pcs[1].to_i)
      else
        write_text('@dre@The overhead icon ID can be no more than 7 and no less than -1.')
      end
    else
      not_found(pcs[0])
    end
  end

  def not_found(cmd)
    write_text("Unable to parse command: #{cmd}")
  end
end