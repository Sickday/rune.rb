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
    when 4 # Chat.
      @context.update(:chat,
                      effects: frame.read_byte(false, :S),
                      color: frame.read_byte(false, :S),
                      text: frame.read_bytes_reverse(frame.header[:length] - 2, :A))
    when 122 # First Item Option.
      RuneRb::Game::Item::Click.parse_option(:first_option, { context: @context, frame: frame })
    when 41 # Second Item option.
      RuneRb::Game::Item::Click.parse_option(:second_option, { context: @context, frame: frame })
    when 16 # Third Item Option.
      RuneRb::Game::Item::Click.parse_option(:third_option, { context: @context, frame: frame })
    when 75 # Forth Item Option.
      RuneRb::Game::Item::Click.parse_option(:fourth_option, { context: @context, frame: frame })
    when 87 # Fifth Item Option.
      RuneRb::Game::Item::Click.parse_option(:fifth_option, { context: @context, frame: frame })


    when 145 # Remove item in slot
      RuneRb::Game::Item::Click.parse_action(:first_action, { context: @context, frame: frame })
    when 77, 78, 165, 189, 210, 226, 121 # Ping frame
      log "Got ping frame #{frame.header[:op_code]}" if RuneRb::DEBUG
    when 86
      roll = frame.read_short(false, :STD, :LITTLE)
      yaw = frame.read_short(false, :STD, :LITTLE)
      log "Camera Rotation: [Roll]: #{roll} || [Yaw]: #{yaw}" if RuneRb::DEBUG

    when 103
      parse_cmd_string(frame.read_string)

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
      return unless steps.positive?

      path = []
      first_x = frame.read_short(false, :A, :LITTLE)
      steps.times do |itr|
        path[itr] ||= []
        path[itr][0] = frame.read_byte(true)
        path[itr][1] = frame.read_byte(true)
      end

      first_y = frame.read_short(false, :STD, :LITTLE)
      @context.toggle_run if frame.read_byte(false, :C) == 1

      positions = []
      steps.times do |itr|
        log "Received step [#{path[itr].inspect}]"
        positions[itr] = RuneRb::Map::Position.new(path[itr][0] + first_x,
                                                   path[itr][1] + first_y)
      end

      @context.push_path(positions.flatten.compact) unless positions.empty?
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
    when 'pos'
      write_text("Your current position: #{@context.position.inspect}")
    when 'maxed'
      @context.profile.stats.max
      @context.update(:skill)
    when 'anim'
      @context.update(:animation, animation: RuneRb::Game::Animation.new(pcs[0].to_i, pcs[1].to_i || 0))
    when 'gfx'
      @context.update(:graphic, graphic: RuneRb::Game::Graphic.new(pcs[0].to_i, pcs[1].to_i || 100, pcs[2].to_i || 0))
    when 'item'
      stack = RuneRb::Game::Item::Stack.new(pcs[1].to_i)
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
      @context.update(:inventory)
    when 'to'
      log RuneRb::COL.green("Moving #{@context.profile[:name]} to #{pcs[1]}, #{pcs[2]}") if RuneRb::DEBUG
      @context.teleport(RuneRb::Map::Position.new(pcs[1].to_i, pcs[2].to_i, pcs[3].to_i || 0))
    when 'mob'
      log RuneRb::COL.green("Morphing into mob: #{pcs[1]}") if RuneRb::DEBUG
      @context.update(:mob, mob_id: pcs[1].to_i)
    when 'promote'
      if RuneRb::Database::Profile[pcs[1]]
        RuneRb::Database::Profile[pcs[1]].update(rights: RuneRb::Database::Profile[pcs[1]][:rights] + 1)
        @context.update(:state)
        @context.update(:chat, text: '', color: 0, effects: 0)
      else
        write_text("Cannot locate profile with name #{pcs[1]}")
      end
    when 'overhead'
      if pcs[1].to_i <= 7 && pcs[1].to_i >= -1
        log RuneRb::COL.green("Changing HeadIcon to #{pcs[1]}") if RuneRb::DEBUG
        @context.update(:head, head_icon: pcs[1].to_i)
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