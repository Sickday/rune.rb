module RuneRb::Net::FrameWriter
  using RuneRb::Patches::ArrayOverrides
  using RuneRb::Patches::IntegerOverrides
  using RuneRb::Patches::StringOverrides

  # Encodes a frame using the Peer#cipher.
  # @param frame [RuneRb::Network::Frame] the frame to encode.
  def encode_frame(frame)
    raise 'Invalid cipher for client!' unless @cipher

    log "Encoding frame: #{frame.inspect}" if RuneRb::DEBUG
    frame.header[:op_code] += @cipher[:encryptor].next_value & 0xFF
    frame
  end

  # Writes a frame to the underlying socket
  # @param frame [RuneRb::Network::MetaFrame] the frame write
  def write_frame(frame)
    raise 'Invalid cipher for write operation!' unless @cipher

    send_data(encode_frame(frame).compile)
  end

  alias << write_frame

  # Writes a frame to the peer's socket
  # @param frame_type [Symbol] the type of frame to write
  # @param data [Hash] the data that will be included in the frame.
  def write(frame_type, data = {})
    case frame_type
    when :sync
      write_frame(RuneRb::Net::Meta::SynchronizationFrame.new(data[:context]))
    when :region
      write_frame(RuneRb::Net::Meta::CenterRegionFrame.new(data[:regional]))
    when :response
      frame = ''
      frame << [data[:response]].pack('c')
      frame << [data[:rights]].pack('c')
      frame << [data[:flagged] ? 1 : 0].pack('c')
      send_data(frame)
    when :login
      # write(:skills, @profile.stats.data)
      # write(:settings, @context.settings.data)
      write(:sidebars)
      write(:sys_message, message: 'Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
      write(:sys_message, message: "VERSION: #{ENV['VERSION']}")
    when :logout, :disconnect
      write_frame(RuneRb::Net::Meta::CloseConnectionFrame.new)
      close_connection(true)
    when :equipment
      data.each { |slot, slot_data| write_frame(RuneRb::Net::Meta::EquipmentSlotFrame.new(slot: slot, slot_data: slot_data)) }
    when :skill
      write_frame(RuneRb::Net::Meta::SkillSlotFrame.new(data))
    when :inventory
      write_frame(RuneRb::Net::Meta::ContextInventoryFrame.new(data, 28))
    when :sidebar
      write_frame(RuneRb::Net::Meta::SwitchSidebarFrame.new(data))
    when :clear_interfaces
      write_frame(RuneRb::Net::Meta::ClearInterfacesFrame.new)
    when :sidebars
      RuneRb::Net::SIDEBAR_INTERFACES.each do |key, value|
        write(:sidebar, menu_id: key, form: value)
      end
    when :interface
      write_frame(RuneRb::Net::Meta::InterfaceFrame.new(data))
    when :overlay
      write_frame(RuneRb::Net::Meta::OverlayInterfaceFrame.new(data))
    when :sys_message
      write_frame(RuneRb::Net::Meta::SystemMessageFrame.new(data))
    else err "Unrecognized frame type! #{frame_type}"
    end
  rescue StandardError => e
    err 'An error occurred while writing frame!'
    puts e
    puts e.backtrace
  end
end