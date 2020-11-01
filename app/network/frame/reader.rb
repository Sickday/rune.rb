## TODO: Lots. Delegate handling of certain frames to their own objects.
module RuneRb::Network::FrameReader
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  private

  # Parses the next readable frame
  def read_frames
    op_code = @in[:raw].next_byte
    length = RuneRb::Network::Constants::PACKET_MAP[op_code]
    length = @in[:raw].next_byte if length == -1
    frame = RuneRb::Network::InFrame.new(op_code, length)
    frame.parse(@socket)
    @in[:parsed] << decode_frame(frame)
    read_frames unless @in[:raw].empty?
  end

  # Decodes a frame using the Peer#cipher.
  # @param frame [RuneRb::Network::Frame] the frame to decode.
  def decode_frame(frame)
    raise 'Invalid cipher for Peer!' unless @cipher

    frame.header[:op_code] -= @cipher[:decryptor].next_value.unsigned(:byte)
    frame
  end

  def handle_frame(frame)
    case frame.header[:op_code]
    when 145 # Remove item in slot
      interface_id = frame.payload.read_short(false, :A)
      slot = @in.read_short(false, :A)
      item_id = @in.read_short(false, :A)
      @player.equipment.remove(slot) if interface_id == 1688
    when 41
      item_id = @in.read_short(false)
      slot = @in.read_short(false, :A)
      interface_id = @in.read_short(false)
      @player.equipment.equip(slot, item_id)
    when 4
      effects = @in.read_byte(false, :S)
      color = @in.read_byte(false, :S)
      length = @current_packet[:length] - 2
      message = @in.read_bytes_reverse(length, :A)
    when 103
    when 248, 164, 98
      length = @current_packet[:length]
      length -= 14 if @current_packet[:op_code] == 248

      steps = (length - 5) / 24
      path = Array.new(steps, Array.new(2))
      first_x = @in.read_short(false, :A, :LITTLE)

      steps.times do |step|
        path[step][0] = @in.read_byte(false)
        path[step][1] = @in.read_byte(false)
      end

      first_y = @in.read_short(false, :STD, :LITTLE)
      run = @in.read_byte(false,:C) == 1

    end
  end
end