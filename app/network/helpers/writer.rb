module RuneRb::Network::FrameWriter
  using RuneRb::System::Patches::ArrayOverrides
  using RuneRb::System::Patches::IntegerOverrides
  using RuneRb::System::Patches::StringOverrides

  # Encodes a frame using the Session#cipher.
  # @param frame [RuneRb::Networkwork::Frame] the frame to encode.
  def encode_frame(frame)
    raise 'Invalid cipher for client!' unless @cipher

    log "Encoding frame: #{frame.inspect}" if RuneRb::GLOBAL[:RRB_DEBUG]
    frame.header[:op_code] += @cipher[:encryptor].next_value & 0xFF
    frame
  end

  # Writes a frame to the underlying socket
  # @param frame [RuneRb::Networkwork::MetaFrame] the frame write
  def write_frame(frame)
    raise 'Invalid cipher for write operation!' unless @cipher

    send_data(encode_frame(frame).compile)
  end

  alias << write_frame

  # Writes a frame to the session's socket
  # @param frame_type [Symbol] the type of frame to write
  # @param data [Hash] the data that will be included in the frame.
  def write(frame_type, data = {})
    case frame_type
    when :sync
      write_frame(RuneRb::Network::Meta::SynchronizationFrame.new(data[:context]))
    when :region
      write_frame(RuneRb::Network::Meta::CenterRegionFrame.new(data[:regional]))
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
      write(:sys_message, message: "VERSION: #{RuneRb::GLOBAL[:VERSION]}")
    when :logout, :disconnect
      write_frame(RuneRb::Network::Meta::CloseConnectionFrame.new)
    when :status
      write_frame(RuneRb::Network::Meta::MembersAndIndex.new(data))
    when :equipment
      data.each { |slot, slot_data| write_frame(RuneRb::Network::Meta::EquipmentSlotFrame.new(slot: slot, slot_data: slot_data)) }
    when :stats
      write(:skill, skill_id: 0, level: data[:attack_level], experience: data[:attack_exp])
      write(:skill, skill_id: 1, level: data[:defence_level], experience: data[:defence_exp])
      write(:skill, skill_id: 2, level: data[:strength_level], experience: data[:strength_exp])
      write(:skill, skill_id: 3, level: data[:hit_points_level], experience: data[:hit_points_exp])
      write(:skill, skill_id: 4, level: data[:range_level], experience: data[:range_exp])
      write(:skill, skill_id: 5, level: data[:prayer_level], experience: data[:prayer_exp])
      write(:skill, skill_id: 6, level: data[:magic_level], experience: data[:magic_exp])
      write(:skill, skill_id: 7, level: data[:cooking_level], experience: data[:cooking_exp])
      write(:skill, skill_id: 8, level: data[:woodcutting_level], experience: data[:woodcutting_exp])
      write(:skill, skill_id: 9, level: data[:fletching_level], experience: data[:fletching_exp])
      write(:skill, skill_id: 10, level: data[:fishing_level], experience: data[:fishing_exp])
      write(:skill, skill_id: 11, level: data[:firemaking_level], experience: data[:firemaking_exp])
      write(:skill, skill_id: 12, level: data[:crafting_level], experience: data[:crafting_exp])
      write(:skill, skill_id: 13, level: data[:smithing_level], experience: data[:smithing_exp])
      write(:skill, skill_id: 14, level: data[:mining_level], experience: data[:mining_exp])
      write(:skill, skill_id: 15, level: data[:herblore_level], experience: data[:herblore_exp])
      write(:skill, skill_id: 16, level: data[:agility_level], experience: data[:agility_exp])
      write(:skill, skill_id: 17, level: data[:thieving_level], experience: data[:thieving_exp])
      write(:skill, skill_id: 18, level: data[:slayer_level], experience: data[:slayer_exp])
      write(:skill, skill_id: 19, level: data[:farming_level], experience: data[:farming_exp])
      write(:skill, skill_id: 20, level: data[:runecrafting_level], experience: data[:runecrafting_exp])
    when :skill
      write_frame(RuneRb::Network::Meta::SkillSlotFrame.new(data))
    when :inventory
      write_frame(RuneRb::Network::Meta::ContextInventoryFrame.new(data, 28))
    when :sidebar
      write_frame(RuneRb::Network::Meta::SwitchSidebarFrame.new(data))
    when :clear_interfaces
      write_frame(RuneRb::Network::Meta::ClearInterfacesFrame.new)
    when :sidebars
      RuneRb::Network::SIDEBAR_INTERFACES.each do |key, value|
        write(:sidebar, menu_id: key, form: value)
      end
    when :interface
      write_frame(RuneRb::Network::Meta::InterfaceFrame.new(data))
    when :overlay
      write_frame(RuneRb::Network::Meta::OverlayInterfaceFrame.new(data))
    when :sys_message
      write_frame(RuneRb::Network::Meta::SystemMessageFrame.new(data))
    else err "Unrecognized frame type! #{frame_type}"
    end
  rescue StandardError => e
    err 'An error occurred while writing frame!'
    puts e
    puts e.backtrace
  end
end