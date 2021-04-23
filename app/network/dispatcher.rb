module RuneRb::Network::Dispatcher

  # Writes a Message to the session's socket
  # @param type [Symbol] the type of Message to write
  # @param data [Hash] the database that will be included in the message.
  def write_message(type, data = {})
    if type == :raw
      write(data[:message], raw: true)
    else
      write(RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:PROTOCOL]][:OUTGOING][type].new(data))
    end
  end

  private

  # Writes data to the underlying <@socket>
  # @param message [RuneRb::Network::Message] a message with data to write.
  def write(message, raw: false)
    raise 'Invalid cipher for write operation!' unless @cipher

    send_data(raw ? message&.compile : encode(message).compile)
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