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

module RuneRb::Network::Parser
  using RuneRb::System::Patches::StringRefinements

  private

  # Decodes a Message using the <@cipher>.
  # @param message [RuneRb::Network::Message] the Message to decode.
  def decode(message)
    raise 'Invalid cipher for Session!' unless @cipher

    message.header[:op_code] = message.header[:op_code] & 0xFF
    log "Raw: #{message.inspect}"
    message.header[:op_code] -= (@cipher[:decryptor].next_value & 0xFF)
    message.header[:op_code] = message.header[:op_code] & 0xFF
    message.header[:length] = RuneRb::Network::MESSAGE_SIZES[message.header[:op_code]]
    message.inspect if RuneRb::GLOBAL[:DEBUG]
    message
  end

  # Reads the next parseable Message object directly from <@socket>.
  def next_message
    @current = RuneRb::Network::Message.new('r', { op_code: @buffer.next_byte })
    @current = decode(@current)
    @current.header[:length] = @buffer.next_byte if @current.header[:length] == -1
    @current.push_data(@buffer.slice!(0...@current.header[:length]))
    parse(@current)
  end

  # Parses a Message object's payload.
  # @param message [RuneRb::Network::Message] the Message to parse.
  def parse(message)
    case message.header[:op_code]
    when 0, 248 then log 'Received Heartbeat!' if RuneRb::GLOBAL[:DEBUG]
    when 45 then log 'Received Mouse Movement' if RuneRb::GLOBAL[:DEBUG] # MouseMovement
    when 77, 78, 165, 189, 210, 226, 121 then log "Got ping message #{message.header[:op_code]}" if RuneRb::GLOBAL[:DEBUG] # Ping
    when 202 then log 'Received Idle Message!' if RuneRb::GLOBAL[:DEBUG] # Idle Messages
    when 4 then @context.update(:message, message: RuneRb::Game::Entity::Message.from_message(message)) # Chat
    when 122 then @context.parse_option(:first_option, message) # First Item Option.
    when 41 then @context.parse_option(:second_option, message) # Second Item option.
    when 16 then @context.parse_option(:third_option, message) # Third Item Option.
    when 75 then @context.parse_option(:fourth_option, message) # Forth Item Option.
    when 87 then @context.parse_option(:fifth_option, message) # Fifth Item Option.
    when 145 then @context.parse_action(:first_action, message) # First Item Action.
    when 214 then @context.parse_action(:switch_item, message) # Switch Item
    when 241 then @context.parse_action(:mouse_click, message) # Mouse Click
    when 103 then @context.parse_command(message) # Commands
    when 185 then @context.parse_button(message) # Button Click
    when 248, 164, 98 then @context.parse_movement(message) # Movement
    when 3 # Window Focus
      focused = message.read(:byte, signed: false)
      log RuneRb::GLOBAL[:COLOR].blue("Client Focus: #{RuneRb::GLOBAL[:COLOR].cyan(focused.positive? ? '[Focused]' : '[Unfocused]')}!") if RuneRb::GLOBAL[:DEBUG]
    when 140 # Screen Rotation
      roll = message.read(:short, { signed: false, mutation: :STD, order: :LITTLE })
      yaw = message.read(:short, { signed: false, mutation: :STD, order: :LITTLE })
      log "Camera Rotation: [Roll]: #{roll} || [Yaw]: #{yaw}" if RuneRb::GLOBAL[:DEBUG]
    when 101 # Character Design
      @context.appearance.from_message(message)
      @context.update(:state)
    else err "Unhandled message: #{message.inspect}"
    end
    next_message if @status[:active] && @status[:auth] == :LOGGED_IN && @buffer.length >= 3
  end
end