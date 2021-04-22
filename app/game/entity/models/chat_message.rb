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
    using RuneRb::System::Patches::StringRefinements
    using RuneRb::System::Patches::IntegerRefinements

    # @return [String] the text contained within the Message
    attr :text

    # @return [Integer] the effects of the Message
    attr :effects

    # @return [Integer] the colors of the Message
    attr :colors

    MessageData = Struct.new(:compressed,
                             :decompressed,
                             :recompressed)

    # Called when a new entity Message is created.
    # @param effects [Integer] the effects the Message will have.
    # @param colors [Integer] the colors the Message will have.
    def initialize(effects, colors, message)
      @effects = effects
      @colors = colors
      parse(message)
    end

    def parse(message)

    end

    class << self
      TRANSLATION_MAP = [' ', 'e', 't', 'a', 'o', 'i', 'h', 'n', 's', 'r', 'd', 'l',
                         'u', 'm', 'w', 'c', 'y', 'f', 'g', 'p', 'b', 'v', 'k', 'x', 'j', 'q', 'z', '0', '1', '2', '3', '4', '5',
                         '6', '7', '8', '9', ' ', '!', '?', '.', ',', ':', ';', '(', ')', '-', '&', '*', '\\', '\'', '@', '#', '+',
                         '=', '\243', '$', '%', '"', '[', ']'].freeze

      # Compresses the passed data into the resulting array of bytes.
      # @param data [String] the string data to compress.
      def compress(data)
        result = []
        data = data.slice!(0..80).downcase!
        carry = -1
        result_idx = 0

        data.length.times do |itr|
          char = data[itr]
          index = TRANSLATION_MAP.index(char) || 0
          index += 195 if index > 12

          if carry == -1
            if index < 13
              carry = index
            else
              result[result_idx += 1] = index
            end
          elsif index < 13
            result[result_idx += 1] = ((carry << 4) + index)
            carry = -1
          else
            result[result_idx += 1] = ((carry << 4) + (index >> 4))
            carry = index & 0xF
          end
        end

        result[result_idx += 1] = (carry << 4) if carry != -1
        result
      end

      def decompress(data, length)
        result = Array.new(4096, 0)
        index = 0
        carry = -1

        length.times do |itr|
          value = data[itr / 2] >> 4 - 4 * (itr % 2 ) & 0xF
          if carry == -1
            if value < 13
              result[index += 1] = TRANSLATION_MAP[value].bytes.first & 0xFF
            else
              carry = value
            end
          else
            result[index += 1] = TRANSLATION_MAP[(carry << 4) + value - 195].bytes.first & 0xFF
            carry = -1
          end
        end

        result[0...index].pack('C*')
      end

      # Slims a substring.
      def slim(text)
        term = true
        text.size.times do |itr|
          if term &&
            text[itr].chr >= 'a' &&
            text[itr].chr <= 'z'
            text[itr] = (text[itr].bytes.first - 0x20).chr
            term = false
          end

          term = true if text[itr].chr == '.'|| text[itr].chr == '!' || text[itr].chr == '?'
        end
        text
      end
    end
  end
end