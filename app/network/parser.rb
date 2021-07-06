module RuneRb::Network::Parser
  using RuneRb::Base::Patches::StringRefinements
  using RuneRb::Base::Patches::IntegerRefinements

  def parse(message)
    if RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:PROTOCOL]][:INCOMING].keys.include?(message.header[:op_code])
      message.class.include(RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:PROTOCOL]][:INCOMING][message.header[:op_code]])
      message.parse(@context)
    else
      raise RuneRb::Base::Errors::UnrecognizedMessage.new(message)
    end
  end

  private

  # Reads data from the <@socket>, producing a readable <RuneRb::Network::Message> object. before attempting to parsing the newly constructed <RuneRb::Network::Message> object.
  def next_message(socket)
    message = RuneRb::Base::Types::Message.new('r', { op_code: socket.read_nonblock(1).unpack1('c') })
    message = decode(message)
    message.header[:length] = (socket.read_nonblock(1).unpack1('c') & 0xFF) if message.header[:length] == -1
    @socket.read_nonblock(message.header[:length], message.payload)
    message
  end

  # Decodes a Message using the <@cipher>.
  # @todo: perhaps make this more flexible to allow toggling on/off of Cipher usage. We should also add some RSA functionality here.
  # @param message [RuneRb::Network::Message] the Message to decode.
  def decode(message)
    raise 'Invalid cipher for Session!' unless @cipher[:incoming]

    message.header[:op_code] = (message.header[:op_code] - @cipher[:incoming].next_value.unsigned(:byte)).unsigned(:byte)
    message.header[:length] = RuneRb::Network::MESSAGE_SIZES[RuneRb::GLOBAL[:PROTOCOL]][message.header[:op_code]]
    message
  end
end

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