# Provides functions to write arbitrary or static messages to a session.
module RuneRb::Network::Helpers::Dispatcher

  # Writes a Message to the session
  # @param message_type [Symbol] the type of message to write
  # @param params [Object] parameters for the message.
  def write_message(message_type, params = {})
    if message_type == :RAW
      send_data(params[:data])
    else
      message = RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::Network::REVISION][:OUTGOING][message_type].new(params)
      send_data(encode(message, @cipher[:outgoing]).compile)
    end
  rescue StandardError => e
    log! e.message, e.backtrace&.join("\n")
  end

  private

  # Encodes a RuneRb::IO::Message using the <@cipher>.
  # @param message [RuneRb::IO::Message] the message to encode.
  def encode(message, cipher)
    message.header.op_code = (message.header.op_code + cipher.next_value) & 0xFF
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