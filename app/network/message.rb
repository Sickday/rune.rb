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
module RuneRb::Network

  # A Message object represents a composable network message that is sent via a Channel object to it's underlying IO source.
  class Message
    include Constants
    include RuneRb::System::Log

    # @return [Hash] the access mode for the message.
    attr :mode

    # @return [Hash] the header for the message.
    attr :header

    # Called when a new Message is created
    # @param mode [String] access mode for the message (r w)
    # @param header [Hash, Struct, Array] an optional header for the message
    # @param body [String, StringIO] an optional body payload for the message.
    # @return [Message] the instance created.
    def initialize(mode, header = { op_code: -1, length: 0 }, type = :VARIABLE_BYTE, body = '')
      raise "Invalid mode for Message! Expecting: r || w || rw , Got: #{mode}" unless 'rw'.include?(mode)

      # Set the mode for the Message object.
      @mode = { raw: mode }

      # Optional header assignment
      @header = header

      # Payload assignment
      @payload = body

      @type = type

      # Enable write functions
      enable_writeable if mode.include?('w')

      # Enable read functions
      enable_readable if mode.include?('r')

      # Return an the instance for chains.
      self
    end

    def inspect
      log! "[Header]: [OpCode]: #{@header[:op_code]} || [Length]: #{@header[:length]} || [Mode]: #{@mode} || [Access]: #{@access} || [Payload]: #{snapshot}"
    end

    class << self
      include Constants
      include RuneRb::System::Log

      # Validates the passed parameters according to the options.
      # @param options [Hash] a map of rules to validate.
      # @todo implement a ValidationError type to be raised when a validation fails.
      def validate(message, operation, options = {})
        return false unless valid_mode?(message, operation)

        # Validate the current access mode if we're in a writeable state
        return false unless valid_access?(message, %i[bit bits].include?(options[:type]) ? :BIT : :BYTE) if message.mode[:writeable]

        # Validate the mutation there are any
        return false unless valid_mutation?(options[:mutation]) if options[:mutation]

        # Validate the byte order if it is passed.
        return false unless valid_order?(options[:order]) if options[:order]

        true
      end

      # Compiles a Hash representation of the header into a binary string.
      # @param header [Hash] the header to compile.
      # @param type [Symbol] the type of header to compile [:FIXED, :VARIABLE_SHORT, :VARIABLE_BYTE]
      # @return [String] binary representation of the header.
      def compile_header(header, type)
        case type
        when :FIXED then [header[:op_code]].pack('C') # Fixed packet lengths are known by both the client and server, so no length packing is necesssary
        when :VARIABLE_SHORT then [header[:op_code], header[:length]].pack('Cn') # Variable Short packet lengths fall into the range of a short type and can be packed as such
        when :VARIABLE_BYTE # Variable Byte packet lengths fall into the range of a byte type and can be packed as such
          if header[:length].nonzero? && header[:length].positive?
            [header[:op_code], header[:length]].pack('Cc')
          else
            compile_header(header, :FIXED)
          end
        when :RAW then return
        else
          compile_header(header, :FIXED)
        end
      end

      private

      # Validates the current access mode for the write channel.
      # @param required [Symbol] the access type required for the operation.
      def valid_access?(message, required)
        unless message.access == required
          err "Invalid access for operation! #{required} access is required for operation!"
          return false
        end
        true
      end

      # Validates the operation with the current mode of the message.
      # @param operation [Symbol] the operation to validate.
      def valid_mode?(message, operation)
        return false if message.mode[:readable] && %i[peek_write write].include?(operation)
        return false if message.mode[:writeable] && %i[peek_read read].include?(operation)

        true
      end

      # Validates the byte mutation for the operation
      # @param mutation [Symbol] the mutation that will be applied in the operation.
      def valid_mutation?(mutation)
        unless BYTE_MUTATIONS.values.any? { |mut| mut.include?(mutation) }
          err "Unrecognized mutation! #{mutation}"
          return false
        end
        true
      end

      # Validates the byte order to read for the operation
      # @param order [Symbol] the order in which to read bytes in the operation.
      def valid_order?(order)
        unless BYTE_ORDERS.include?(order)
          err "Unrecognized byte order! #{order}"
          return false
        end
        true
      end
    end

    # Fetches a snapshot of the message payload content.
    # @return [String] a snapshot of the payload
    def peek
      @payload.dup
    end

    alias snapshot peek

    private

    # Mutates the value according to the passed mutation
    # @param value [Integer] the value to mutate
    # @param mutation [Symbol] the mutation to apply to the value.
    # @todo Testcase: Test that mutations are properly applied
    # @todo Testcase: Test that mutations are properly parsed up to this point.
    def mutate(value, mutation)
      case mutation
      when *BYTE_MUTATIONS[:std] then value
      when *BYTE_MUTATIONS[:add] then value += 128
      when *BYTE_MUTATIONS[:neg] then value = -value
      when *BYTE_MUTATIONS[:sub] then value = 128 - value
      end
      value
    end

    # Enables Writeable functions for the Message.
    def enable_writeable
      # Set access var for bit and byte writing.
      @access = :BYTE

      # Set the initial bit position for bit writing.
      @bit_position = 0

      # Define functions on the message instance.
      require_relative 'message/writeable'
      self.class.include(Writeable)

      # Update the message mode
      @mode[:writeable] = true
    end

    # Enables Readable functions for the Message.
    def enable_readable
      # Define functions on the message instance.
      require_relative 'message/readable'
      self.class.include(Readable)

      # Update the message mode
      @mode[:readable] = true
    end

    # Updates the length of the <@header>
    def update_length
      @header[:length] = @payload.bytesize
    end
  end
end