module RuneRb::Net::FrameReader
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  private

  # Decodes a frame using the Session#cipher.
  # @param frame [RuneRb::Network::Frame] the frame to decode.
  def decode_frame(frame)
    raise 'Invalid cipher for Session!' unless @cipher

    frame.header[:op_code] -= @cipher[:decryptor].next_value & 0xFF
    frame.header[:op_code] = frame.header[:op_code] & 0xFF
    frame.header[:length] = RuneRb::Net::PACKET_MAP[frame.header[:op_code]]
    log "Decoding frame: #{frame.inspect}" if RuneRb::DEBUG
    frame
  end

  # Reads the next parseable frame from Session#in, then attempts to handle the frame accordingly.
  def next_frame
    @current = RuneRb::Net::Frame.new(@in.next_byte)
    @current = decode_frame(@current)
    @current.header[:length] = @in.next_byte if @current.header[:length] == -1
    @current.header[:length].times { @current.push(@in.slice!(0)) }
    parse_frame(@current)
  end

  # Processes the frame parameter
  # @param frame [RuneRb::Network::StaticFrame] the frame to handle
  def parse_frame(frame)
    case frame.header[:op_code]
    when 0
      log 'Received Heartbeat!' if RuneRb::DEBUG
    when 45 # MouseMovement
      log 'Received Mouse Movement' if RuneRb::DEBUG
    when 3 # Window Focus
      focused = frame.read_byte(false)
      log RuneRb::COL.blue("Client Focus: #{RuneRb::COL.cyan(focused.positive? ? '[Focused]' : '[Unfocused]')}!") if RuneRb::DEBUG
    when 4 # Chat.
      @context.update(:message, message: RuneRb::Entity::Message.new(frame.read_byte(false, :S),
                                                                     frame.read_byte(false, :S),
                                                                     frame.read_bytes_reverse(frame.header[:length] - 2, :A),
                                                                     @context.profile.rights))
    when 122 # First Item Option.
      @context.parse_option(:first_option, frame)
    when 41 # Second Item option.
      @context.parse_option(:second_option, frame)
    when 16 # Third Item Option.
      @context.parse_option(:third_option, frame)
    when 75 # Forth Item Option.
      @context.parse_option(:fourth_option, frame)
    when 87 # Fifth Item Option.
      @context.parse_option(:fifth_option, frame)
    when 145 # First Item Action.
      @context.parse_action(:first_action, frame)
    when 214 # Switch Item
      @context.parse_action(:switch_item,  frame)
    when 241 # Mouse Click
      @context.parse_action(:mouse_click, frame)
    when 77, 78, 165, 189, 210, 226, 121 # Ping frame
      log "Got ping frame #{frame.header[:op_code]}" if RuneRb::DEBUG
    when 86
      roll = frame.read_short(false, :STD, :LITTLE)
      yaw = frame.read_short(false, :STD, :LITTLE)
      log "Camera Rotation: [Roll]: #{roll} || [Yaw]: #{yaw}" if RuneRb::DEBUG
    when 101 # Character Design
      @context.appearance.from_frame(frame)
      @context.update(:state)
    when 103
      @context.parse_command(frame)
    when 185 # Button Click
      @context.parse_button(frame)
    when 202
      log 'Received Idle Frame!' if RuneRb::DEBUG
    when 248, 164, 98 # Movement
      @context.parse_movement(frame)
    else
      err "Unhandled frame: #{frame.inspect}"
    end
    # Parse the next frame if there's still data in the buffer.
    next_frame if @in.size >= 3
  rescue StandardError => e
    err 'An error occurred while parsing frame!'
    err frame.inspect
    puts e
    puts e.backtrace
  end
end