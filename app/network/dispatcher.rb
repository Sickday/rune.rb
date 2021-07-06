module RuneRb::Network::Dispatcher
  using RuneRb::Base::Patches::IntegerRefinements

  # Writes a Message to the <@socket>
  # @param type [Symbol] the type of Message to write
  # @param data [Hash] the data that will be used to construct the message.
  def write_message(type, data = {})
    if type == :raw
      send_data(data[:message]&.compile)
    else
      send_data(encode(RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:PROTOCOL]][:OUTGOING][type].new(data)).compile)
    end
  end

  private

  # Encodes a RuneRb::Network::Message using the <@cipher>.
  # @param message [RuneRb::Base::Types::Message] the message to encode.
  def encode(message)
    raise 'Invalid outgoing cipher!' unless @cipher[:outgoing]

    message.header[:length] = message.peek.bytesize
    message.inspect if RuneRb::GLOBAL[:DEBUG]
    message.header[:op_code] += @cipher[:outgoing].next_value.unsigned(:byte)
    message
  end

  alias << write_message
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