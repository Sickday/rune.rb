# A Message object represents a composable network frame that is sent via a Channel object to it's underlying IO source.
class Message
  include Constants

  # @return [Hash] the access mode for the message.
  attr :mode

  # @return [Hash, Struct] the header for the message.
  attr :header

  # Called when a new Message is created
  # @param mode [String] access mode for the message (r w)
  # @param header [Hash, Struct] an optional header for the message
  # @param body [String, StringIO] an optional body payload for the message.
  def initialize(mode, header = nil, body = nil)
    raise "Invalid mode for buffer! Expecting: r || w || rw , Got: #{mode}" unless 'rw'.include?(mode)

    @mode = {}
    @mode[:raw] = mode

    # Enable write functions
    enable_writeable(header, body) if mode.include?('w')

    # Enable read functions
    enable_readable(header, body) if mode.include?('r')
  end

  def inspect
    "[Header]: OpCode: #{@header[:op_code]} || Size: #{@header[:length]}\n[Payload]: #{snapshot(:readable) || snapshot(:writeable)}\n" +
    "[Mode]: #{@mode} || [Access]: #{@access}"
  end

  class << self
    include Constants
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

    private

    # Validates the current access mode for the write channel.
    # @param required [Symbol] the access type required for the operation.
    def valid_access?(message, required)
      unless message.access == required
        puts "Access Violation! #{required} access is required for operation!"
        return false
      end
      true
    end

    # Validates the operation with the current mode of the message.
    # @param operation [Symbol] the operation to validate.
    def valid_mode?(message, operation)
      return true if (message.mode[:readable] && %i[peek_read read].include?(operation))
      return true if (message.mode[:writeable] && %i[peek_write write].include?(operation))
      false
    end

    # Validates the byte mutation for the operation
    # @param mutation [Symbol] the mutation that will be applied in the operation.
    def valid_mutation?(mutation)
      unless BYTE_MUTATIONS.values.any? { |mut| mut.include?(mutation) }
        puts "Unrecognized mutation! #{mutation}"
        return false
      end
      true
    end

    # Validates the byte order to read for the operation
    # @param order [Symbol] the order in which to read bytes in the operation.
    def valid_order?(order)
      unless BYTE_ORDERS.include?(order)
        puts "Unrecognized byte order! #{order}"
        return false
      end
      true
    end
  end

  # Fetches a snapshot of the message content depending on the passed type.
  # @param type [Symbol] the type of content to peek into [:readable, :writable]
  # @return [String] a snapshot of the payload
  def peek(type)
    case type
    when :writeable
      if Message.validate(self, :peek_write)
        @writeable.dup
      end
    when :readable
      if Message.validate(self, :peek_read)
        @readable.is_a?(NIO::ByteBuffer) ? @readable.dup.get : @readable.dup
      end
    end
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

  # Enables Writeable functions for the Message. Under the hood, the Writable module is included, the initial Message#header is created, bit_position is initialized and mode is set.
  # @param header [Hash, Struct] the header for the Writable Message.
  # @param body [String, StringIO] the body for the Writable Message.
  def enable_writeable(header = nil, body = '')
    # Initialize the header
    @header = header || { op_code: -1, length: -1 }

    # Initialize the writable content body.
    @writeable = body

    # Set access var for bit and byte writing.
    @access = :BYTE

    # Set the initial bit position for bit writing.
    @bit_position = 0

    # Define functions on the channel instance.
    self.class.include(Writeable)

    # Update the channel mode
    @mode[:writeable] = true
  end

  # Enables Readable functions for the Message. Under the hood, the Readable module is included, the initialize Message#header is created if it does not exist, then set and frozen as Readable Messages should not have modifiable headers.
  # @param header [Hash, Struct] the header for the Readable Message.
  # @param body [String, StringIO] the body for the Readable Message.
  def enable_readable(header = nil, body = '')
    # Initialize the header. Header is frozen as Readable Messages should not have modifiable headers.
    @header = header.freeze || { op_code: -1, length: -1 }.freeze

    # Initialize the readable payload.
    @readable = body

    # Define functions on the channel instance.
    self.class.include(Readable)

    # Update the channel mode
    @mode[:readable] = true
  end
end