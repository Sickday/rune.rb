module RuneRb::Network
  # Represents a composable/decomposable network message that is either sent or received via a TCPSocket.
  class Message
    include RuneRb::Utils::Logging

    # @return [Struct] the header for the message.
    attr :header

    # @return [Buffer] the access mode for the message.
    attr :body

    # Models the heading of a protocol data unit received from a peer socket.
    # @param op_code [Integer] the Operation Code of the data unit
    # @param length [Integer] the length of data unit's payload, excluding the header.
    # @param type [Symbol] the type of header of the data unit.
    # @return [Struct]
    Header = Struct.new(:op_code, :length, :type) do

      # Generates a binary string representation of the {Header} object.
      # @return [String, NilClass] binary representation of the header.
      def compile_header
        case self.type
        when :FIXED then [self.op_code].pack('C') # Fixed packet lengths are known by both the client and server, so no length packing is necesssary
        when :RAW then ''
        when :VARIABLE_SHORT then [self.op_code, self.length].pack('Cn') # Variable Short packet lengths fall into the range of a short type and can be packed as such
        when :VARIABLE_BYTE # Variable Byte packet lengths fall into the range of a byte type and can be packed as such
          if self.length.nonzero? && self.length.positive?
            [self.op_code, self.length].pack('Cc')
          elsif self.length.nonzero? && self.length.negative?
            self.type = :FIXED
            compile_header
          end
        else compile_header
        end
      end

      def inspect
        "[Header]: [OpCode]: #{self.op_code} || [Length]: #{self.length}"
      end
    end

    # Called when a new Message is created
    # @param op_code [Integer] the message's operation code.
    # @param type [Symbol] the message type. [:VARIABLE_BYTE, :VARIABLE_SHORT, :FIXED]
    # @param body [String, StringIO, RuneRb::Network::Buffer] an optional body payload for the message.
    # @return [Message] the instance created.
    def initialize(op_code: -1, type: :FIXED, body: RuneRb::Network::Buffer.new('rw'))
      @header = Header.new(op_code, 0, type)
      @body = case body
              when RuneRb::Network::Buffer then body
              when String, StringIO then RuneRb::Network::Buffer.new('r', data: body)
              else raise "Invalid body type for message! Expecting: Buffer, StringIO, String Got: #{body.class}"
              end
      update_length

      self
    end

    # Compiles the {Message} into a string of binary data.
    # @return [String] binary representation of the message.
    def compile
      @header.compile_header + @body.snapshot
    end

    def inspect
      "#{@header.inspect} || #{@body.inspect}"
    end

    # @abstract parses the message object.
    def parse(_ctx); end

    # Read data from the {Message#body}
    def read(type: :byte, signed: false, mutation: :STD, order: 'BIG')
      @body.read(type: type, signed: signed, mutation: mutation, order: order)
    end

    # Write data to the {Message#body}
    def write(value, type: :byte, mutation: :STD, order: 'BIG', options: {})
      @body.write(value, type: type, mutation: mutation, order: order, options: options)
      update_length
      self
    end

    private

    # Updates the length of the <@header>
    def update_length
      @header.length = @body.length
    end
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