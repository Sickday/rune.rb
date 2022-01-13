module RuneRb::Network::Helpers::Parser
  using RuneRb::Utils::Patches::StringRefinements
  using RuneRb::Utils::Patches::IntegerRefinements

  # Parses a message object for a specific context
  # @param message [RuneRb::Network::Message] the message to parse
  def parse(message)
    if RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:ENV].server_config.revision][:INCOMING].keys.include?(message.header.op_code)
      message.singleton_class.include(RuneRb::Network::PROTOCOL_TEMPLATES[RuneRb::GLOBAL[:ENV].server_config.revision][:INCOMING][message.header.op_code])
      message.parse(@context)
    else
      log! "Unrecognized message! #{message.inspect}"
    end
  end

  private

  # Reads data from the <buffer> parameter, producing a readable <RuneRb::Network::Message> object.
  # @param buffer [RuneRb::Network::Buffer] the buffer to read the next message from
  # @return [RuneRb::Network::Message] the parsed message.
  def next_message(buffer, cipher)
    opcode = (buffer.read_byte - cipher.next_value & 0xFF).unsigned(:byte)
    length = RuneRb::Network::MESSAGE_SIZES[RuneRb::GLOBAL[:ENV].server_config.revision][opcode]
    length = buffer.read_byte if length.negative?
    body = length.times.inject('') { _1 << buffer.data.read_nonblock(1) }
    RuneRb::Network::Message.new(op_code: opcode, body: body)
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