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

  # Reads data from the <@buffer>, producing a <RuneRb::Network::Message> object from the read data before attempting to parsing the newly constructed <RuneRb::Network::Message> object.
  def next_message
    @current = RuneRb::Network::Message.new('r', { op_code: @buffer.next_byte })
    @current = decode(@current)
    @current.header[:length] = @buffer.next_byte if @current.header[:length] == -1
    @current.push_data(@buffer.slice!(0...@current.header[:length]))

    if RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:PROTOCOL]][:INCOMING].keys.include?(@current.header[:op_code])
      ##
      # LOL
      @current.class.include(RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:PROTOCOL]][:INCOMING][@current.header[:op_code]])
      @current.parse(@context)
    else
      log! RuneRb::GLOBAL[:COLOR].magenta.bold("Unhandled Message with Operation Code: #{@current.header[:op_code]}")
    end

    next_message if @status[:active] && @status[:auth] == :LOGGED_IN && @buffer.length >= 8
  end

  # Decodes a Message using the <@cipher>.
  # @param message [RuneRb::Network::Message] the Message to decode.
  def decode(message)
    raise 'Invalid cipher for Session!' unless @cipher

    message.header[:op_code] = message.header[:op_code] & 0xFF
    log "Raw: #{message.inspect}"
    message.header[:op_code] -= (@cipher[:decryptor].next_value & 0xFF)
    message.header[:op_code] = message.header[:op_code] & 0xFF
    message.header[:length] = RuneRb::Network::MESSAGE_SIZES[RuneRb::GLOBAL[:PROTOCOL]][message.header[:op_code]]
    message
  end
end