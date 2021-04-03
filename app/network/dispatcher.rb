# Copyright (c) 2021, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module RuneRb::Network::Dispatcher

  # Writes a Message to the session's socket
  # @param type [Symbol] the type of Message to write
  # @param data [Hash] the database that will be included in the message.
  def write_message(type, data = {})
    case type
    when :raw then write(data[:message])
    when :clear_interfaces then write(RuneRb::Network::Templates::ClearInterfacesMessage.new)
    when :equipment then data.each { |slot, slot_data| write(RuneRb::Network::Templates::EquipmentSlotMessage.new(slot: slot, slot_data: slot_data)) }
    when :interface then write(RuneRb::Network::Templates::InterfaceMessage.new(data))
    when :inventory then write(RuneRb::Network::Templates::ContextInventoryMessage.new(data, 28))
    when :logout, :disconnect then write(RuneRb::Network::Templates::LogoutMessage.new)
    when :overlay then write(RuneRb::Network::Templates::OverlayMessage.new(data))
    when :region then write(RuneRb::Network::Templates::CenterRegionMessage.new(data[:regional]))
    when :sidebar then write(RuneRb::Network::Templates::SwitchSidebarMessage.new(data))
    when :sidebars then RuneRb::Network::SIDEBAR_INTERFACES.each { |key, value| write_message(:sidebar, menu_id: key, form: value) }
    when :stat, :skill then write(RuneRb::Network::Templates::StatMessage.new(data))
    when :status then write(RuneRb::Network::Templates::MembersAndIndexMessage.new(data))
    when :sync then write(RuneRb::Network::Templates::SynchronizationMessage.new(@context))
    when :sys_message then write(RuneRb::Network::Templates::ServerTextMessage.new(data))
    when :login
      write_message(:status, members: @context.status.members, player_idx: @context.index)
      # write_message(:settings, @context.settings.database)
      write_message(:sidebars)
      # write_message(:inventory, @context.inventory[:container].database)
      # write_message(:skills, @context.profile.stats)
      write_message(:sys_message, message: 'Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
      write_message(:sys_message, message: "VERSION: #{RuneRb::GLOBAL[:VERSION]}")
    when :response
      message = ''
      message << [data[:response]].pack('c')
      message << [data[:rights]].pack('c')
      message << [data[:flagged] ? 1 : 0].pack('c')
      send_data(message)
    when :stats, :skills
      write_message(:skill, skill_id: 0, level: data[:attack_level], experience: data[:attack_exp])
      write_message(:skill, skill_id: 1, level: data[:defence_level], experience: data[:defence_exp])
      write_message(:skill, skill_id: 2, level: data[:strength_level], experience: data[:strength_exp])
      write_message(:skill, skill_id: 3, level: data[:hit_points_level], experience: data[:hit_points_exp])
      write_message(:skill, skill_id: 4, level: data[:range_level], experience: data[:range_exp])
      write_message(:skill, skill_id: 5, level: data[:prayer_level], experience: data[:prayer_exp])
      write_message(:skill, skill_id: 6, level: data[:magic_level], experience: data[:magic_exp])
      write_message(:skill, skill_id: 7, level: data[:cooking_level], experience: data[:cooking_exp])
      write_message(:skill, skill_id: 8, level: data[:woodcutting_level], experience: data[:woodcutting_exp])
      write_message(:skill, skill_id: 9, level: data[:fletching_level], experience: data[:fletching_exp])
      write_message(:skill, skill_id: 10, level: data[:fishing_level], experience: data[:fishing_exp])
      write_message(:skill, skill_id: 11, level: data[:firemaking_level], experience: data[:firemaking_exp])
      write_message(:skill, skill_id: 12, level: data[:crafting_level], experience: data[:crafting_exp])
      write_message(:skill, skill_id: 13, level: data[:smithing_level], experience: data[:smithing_exp])
      write_message(:skill, skill_id: 14, level: data[:mining_level], experience: data[:mining_exp])
      write_message(:skill, skill_id: 15, level: data[:herblore_level], experience: data[:herblore_exp])
      write_message(:skill, skill_id: 16, level: data[:agility_level], experience: data[:agility_exp])
      write_message(:skill, skill_id: 17, level: data[:thieving_level], experience: data[:thieving_exp])
      write_message(:skill, skill_id: 18, level: data[:slayer_level], experience: data[:slayer_exp])
      write_message(:skill, skill_id: 19, level: data[:farming_level], experience: data[:farming_exp])
      write_message(:skill, skill_id: 20, level: data[:runecrafting_level], experience: data[:runecrafting_exp])
    else err "Unrecognized message type! #{type}"
    end
  end

  private

  # Writes a message to the underlying <@socket>
  # @param message [RuneRb::Network::Message] the message to write.
  def write(message)
    raise 'Invalid cipher for write operation!' unless @cipher

    send_data(encode(message).compile)
  end

  # Encodes a RuneRb::Network::Message using the <@cipher>.
  # @param message [RuneRb::Network::Message] the message to encode.
  def encode(message)
    raise 'Invalid cipher for client!' unless @cipher

    message.header[:length] = message.peek.bytesize
    message.inspect if RuneRb::GLOBAL[:DEBUG]
    message.header[:op_code] += @cipher[:encryptor].next_value & 0xFF
    message
  end

  alias << write
end