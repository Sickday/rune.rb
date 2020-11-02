module RuneRb::Network::FrameReader
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  private

  # Parses the next readable frame
  def next_frame
    @in << @socket.read_nonblock(128)
    @current = RuneRb::Network::InFrame.new(@in.next_byte)
    @current = decode_frame(@current)
    @current.header[:length] = @in.next_byte if @current.header[:length] == -1
    @current.header[:length].times { @current.push(@in.slice!(0)) }
    handle_frame(@current)
  end

  # Decodes a frame using the Peer#cipher.
  # @param frame [RuneRb::Network::Frame] the frame to decode.
  def decode_frame(frame)
    raise 'Invalid cipher for Peer!' unless @cipher

    frame.header[:op_code] -= @cipher[:decryptor].next_value & 0xFF
    frame.header[:op_code] = frame.header[:op_code] & 0xFF
    frame.header[:length] = RuneRb::Network::Constants::PACKET_MAP[frame.header[:op_code]]
    frame
  end

  # Processes the frame parameter
  # @param frame [RuneRb::Network::InFrame] the frame to handle
  def handle_frame(frame)
    case frame.header[:op_code]
    when 0 then nil
    when 145 # Remove item in slot
      interface_id = frame.read_short(false, :A)
      slot = frame.read_short(false, :A)
      item_id = frame.read_short(false, :A)
      # TODO: Parse RemoveItemInSlot frame
    when 41
      item_id = frame.read_short(false)
      slot = frame.read_short(false, :A)
      interface_id = frame.read_short(false)
      # TODO: Parse EquipItem frame
    when 4
      effects = frame.read_byte(false, :S)
      color = frame.read_byte(false, :S)
      message = frame.read_bytes_reverse(frame.header[:length] - 2, :A)
      # TODO: Parse Chat frame
    when 103
      command = frame.read_string
      # TODO: Parse Command frame
    when 248, 164, 98
      length = frame.header[:length]
      length -= 14 if frame.header[:op_code] == 248

      steps = (length - 5) / 24
      path = Array.new(steps, Array.new(2))
      first_x = frame.read_short(false, :A, :LITTLE)

      steps.times do |step|
        path[step][0] = frame.read_byte(false)
        path[step][1] = frame.read_byte(false)
      end

      first_y = frame.read_short(false, :STD, :LITTLE)
      run = frame.read_byte(false, :C) == 1
      # TODO: Finish reading
      # TODO: Parse WalkingFrame
    else
      err "Unhandled frame: #{frame.inspect}"
    end
  end
end