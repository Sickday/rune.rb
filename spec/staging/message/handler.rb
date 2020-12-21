# This module provides functions for processing and composing messages that are sent and received over a channel.
module MessageHandler
  # Process messages asynchronously
  # @param message [RuneRb::Network::Message] the message to parse
  def process(message, task: Async::Task.current)
    case message.header[:op_code]
    when 0 then log! 'Received Heartbeat!' if RuneRb::GLOBAL[:RRB_DEBUG] # Heartbeat
    when 3 then log! RuneRb::COL.blue("Client Focus: #{RuneRb::COL.cyan(message.read.positive? ? '[Focused]' : '[Unfocused]')}!") if RuneRb::GLOBAL[:RRB_DEBUG] # Window Focus
    when 4 then task.async { @context.update(:message, message: RuneRb::Game::Entity::ChatMessage.from_message(message)) } # Chat.
    when 45 then log! 'Received Mouse Movement' if RuneRb::GLOBAL[:RRB_DEBUG] # MouseMovement
    when 103 then task.async { @context.parse_command(message) } # Command
    when 248, 164, 98 then task.async { @context.parse_movement(message) } # Movement
    when 202 then log! 'Received Idle Frame!' if RuneRb::GLOBAL[:RRB_DEBUG]
    when 122 then task.async { @context.parse_option(:first_option, message) } # First Item Option.
    when 41 then task.async { @context.parse_option(:second_option, message) } # Second Item option.
    when 16 then task.async { @context.parse_option(:third_option, message) } # Third Item Option.
    when 75 then task.async { @context.parse_option(:fourth_option, message) } # Forth Item Option.
    when 87 then task.async { @context.parse_option(:fifth_option, message) } # Fifth Item Option.
    when 145 then task.async { @context.parse_action(:first_action, message) } # First Item Action.
    when 214 then task.async { @context.parse_action(:switch_item,  message) } # Switch Item
    when 185 then task.async {  @context.parse_button(message) } # Button Click
    when 241 then task.async { @context.parse_action(:mouse_click, message) } # Mouse Click
    when 77, 78, 165, 189, 210, 226, 121 then log! "Got ping frame #{message.header[:op_code]}" if RuneRb::GLOBAL[:RRB_DEBUG] # Ping frame
    when 86
      roll = message.read(type: :short, signed: false, order: :LITTLE)
      yaw = message.read(type: :short, signed: false, order: :LITTLE)
      log "Camera Rotation: [Roll]: #{roll} || [Yaw]: #{yaw}" if RuneRb::GLOBAL[:RRB_DEBUG]
    when 101 # Character Design
      task.async do
        @context.appearance.from_message(message)
        @context.update(:state)
      end
    else err "Unhandled frame: #{message.inspect}"
    end
    next_message(task: task) if @status[:active] && @status[:auth] == :LOGGED_IN
  rescue StandardError => e
    err 'An error occurred while parsing frame!', e
    err message.inspect
    puts e.backtrace
  end

  # Composes a message to be sent via the session's channel
  # @param message_type [Symbol] the type of message to write
  # @param attachments [Hash] the data that will be included in the message.
  # @return [RuneRb::Network::Message, Array] the composed message or messages ready to be sent over the channel
  def compose(message_type, attachments = {})
    case message_type
    when :sync then RuneRb::Network::Meta::SynchronizationFrame.new(attachments[:context])
    when :region then RuneRb::Network::Meta::CenterRegionFrame.new(attachments[:regional])
    when :interface then RuneRb::Network::Meta::InterfaceFrame.new(attachments[:id])
    when :overlay then RuneRb::Network::Meta::OverlayInterfaceFrame.new(attachments[:id])
    when :sys_message then RuneRb::Network::Meta::SystemMessageFrame.new(attachments[:message])
    when :skill then RuneRb::Network::Meta::SkillSlotFrame.new(attachments[:skill_data])
    when :inventory then RuneRb::Network::Meta::ContextInventoryFrame.new(attachments[:inventory_data], 28)
    when :sidebar then RuneRb::Network::Meta::SwitchSidebarFrame.new(menu_id: attachments[:sidebar_id], form: attachments[:sidebar_form])
    when :clear_interfaces then RuneRb::Network::Meta::ClearInterfacesFrame.new
    when :logout, :disconnect then RuneRb::Network::Meta::CloseConnectionFrame.new
    when :status then RuneRb::Network::Meta::MembersAndIndex.new(attachments)
    when :equipment then RuneRb::Network::Meta::GearSlotFrame.new(slot: attachments[:slot], data: attachments[:item])
    when :response
      body = ''
      body << [attachments[:response]].pack('c')
      body << [attachments[:rights]].pack('c')
      body << [attachments[:flagged] ? 1 : 0].pack('c')
      body
    when :login
      compose(:sidebars) +
        compose(:stats) +
        # compose(:settings, @context.settings) +
        # compose(:status, @context.status) +
        [message_1: compose(:sys_message, message: 'Check the repository for updates! https://gitlab.com/Sickday/rune.rb'),
         message_2: compose(:sys_message, message: "VERSION: #{RuneRb::GLOBAL[:VERSION]}") ]
    when :gear then attachments.each { |slot, slot_data| compose(:equipment, slot: slot, item: slot_data) }
    when :sidebars then RuneRb::Network::SIDEBAR_INTERFACES.each { |key, value| compose(:sidebar, menu_id: key, form: value) }
    when :stats
      [ compose(:skill, skill_id: 0, level: data[:attack_level], experience: data[:attack_exp]),
        compose(:skill, skill_id: 1, level: data[:defence_level], experience: data[:defence_exp]),
        compose(:skill, skill_id: 2, level: data[:strength_level], experience: data[:strength_exp]),
        compose(:skill, skill_id: 3, level: data[:hit_points_level], experience: data[:hit_points_exp]),
        compose(:skill, skill_id: 4, level: data[:range_level], experience: data[:range_exp]),
        compose(:skill, skill_id: 5, level: data[:prayer_level], experience: data[:prayer_exp]),
        compose(:skill, skill_id: 6, level: data[:magic_level], experience: data[:magic_exp]),
        compose(:skill, skill_id: 7, level: data[:cooking_level], experience: data[:cooking_exp]),
        compose(:skill, skill_id: 8, level: data[:woodcutting_level], experience: data[:woodcutting_exp]),
        compose(:skill, skill_id: 9, level: data[:fletching_level], experience: data[:fletching_exp]),
        compose(:skill, skill_id: 10, level: data[:fishing_level], experience: data[:fishing_exp]),
        compose(:skill, skill_id: 11, level: data[:firemaking_level], experience: data[:firemaking_exp]),
        compose(:skill, skill_id: 12, level: data[:crafting_level], experience: data[:crafting_exp]),
        compose(:skill, skill_id: 13, level: data[:smithing_level], experience: data[:smithing_exp]),
        compose(:skill, skill_id: 14, level: data[:mining_level], experience: data[:mining_exp]),
        compose(:skill, skill_id: 15, level: data[:herblore_level], experience: data[:herblore_exp]),
        compose(:skill, skill_id: 16, level: data[:agility_level], experience: data[:agility_exp]),
        compose(:skill, skill_id: 17, level: data[:thieving_level], experience: data[:thieving_exp]),
        compose(:skill, skill_id: 18, level: data[:slayer_level], experience: data[:slayer_exp]),
        compose(:skill, skill_id: 19, level: data[:farming_level], experience: data[:farming_exp]),
        compose(:skill, skill_id: 20, level: data[:runecrafting_level], experience: data[:runecrafting_exp]) ]

    else err "Unrecognized message type! #{message_type}"
    end
  rescue StandardError => e
    err 'An error occurred while composing message!'
    puts e
    puts e.backtrace
  end
end