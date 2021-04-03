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

module RuneRb::Game::Entity

  # A entity Message is the object created when an Entity chats via the chatbox.
  class ChatMessage
    # @return [String] the text contained within the Message
    attr :text

    # @return [Integer] the effects of the Message
    attr :effects

    # @return [Integer] the colors of the Message
    attr :colors

    # Called when a new entity Message is created.
    # @param text [String] The text contained within the Message.
    # @param effects [Integer] the effects the Message will have.
    # @param colors [Integer] the colors the Message will have.
    def initialize(effects, colors, text)
      @text = text
      @effects = effects
      @colors = colors
    end

    def self.from_message(message)
      RuneRb::Game::Entity::ChatMessage.new(message.read(:byte, signed: false, mutation: :S),
                                        message.read(:byte, signed: false, mutation: :S),
                                        message.read(:reverse, length: message.header[:length] - 2, mutation: :A))
    end
  end
end