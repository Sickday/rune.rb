# A Message object represents a composable network frame that is sent via a Channel object to it's underlying IO source.
class Message
  include Constants

  # @return [Hash] the access mode for the message.
  attr :mode

  # @return [Hash, Struct] the header for the message.
  attr :header

  # A Header object structures a Message's content header. It provides a #compile_for function to compile itself for a specific content body.
  # @param op_code [Integer] the Operation Code for the Message Header.
  # @param length [Integer] the length of the content body of the Message.
  Header = Struct.new(:op_code, :length) do

    # Compiles the header for a content object.
    # @param content [String, StringIO] the content to compile the header for.
    # @param type [Symbol] the type of header to compile [:FIXED, :VARIABLE_SHORT, :VARIABLE_BYTE]
    def compile_for(content, type = :FIXED)
      case type
      when :FIXED then [self.op_code].pack('C')
      when :VARIABLE_SHORT then [self.op_code, content.bytesize].pack('Cn')
      when :VARIABLE_BYTE
        if self.length&.nonzero? && self.length&.positive?
          [self.op_code, self.length].pack('CC')
        else
          compile_for(content, :FIXED)
        end
      end
    end

    def inspect
      "[OpCode]: #{self.op_code} || [Length]: #{self.length}"
    end
  end

  # Called when a new Message is created
  # @param mode [String] access mode for the message (r w)
  # @param header [Hash, Struct, Array] an optional header for the message
  # @param body [String, StringIO] an optional body payload for the message.
  def initialize(mode, header = {}, body = nil)
    raise "Invalid mode for Message! Expecting: r || w || rw , Got: #{mode}" unless 'rw'.include?(mode)

    @mode = {}.tap { |hash| hash[:raw] = mode }
    @header = Header.new(header[:op_code] || -1, header[:size] || header[:length] || -1)
    # Enable write functions
    enable_writeable(body) if mode.include?('w')

    # Enable read functions
    enable_readable(body) if mode.include?('r')
  end

  def inspect
    "[Header]: #{@header.inspect} || [Mode]: #{@mode} || [Access]: #{@access} || [Payload]: #{snapshot(:readable) || snapshot(:writeable)}"
  end

  class << self
    include Constants

    # Validates the passed parameters according to the options.
    # @param options [Hash] a map of rules to validate.
    # @todo implement a ValidationError type to be raised when a validation fails.
    def validate(message, operation, options = {})
      return false unless valid_mode?(message, operation)

      # Validate the current access mode if we're in a writeable state
      return false if message.mode[:writeable] && !valid_access?(message, %i[bit bits].include?(options[:type]) ? :BIT : :BYTE)

      # Validate the mutation there are any
      return false if options[:mutation] && !valid_mutation?(options[:mutation])

      # Validate the byte order if it is passed.
      return false if options[:order] && !valid_order?(options[:order])

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
      return true if message.mode[:readable] && %i[peek_read read].include?(operation)
      return true if message.mode[:writeable] && %i[peek_write write].include?(operation)

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
  #
  # Important: Originally, I tried to play this safe by calling Object#dup on any readable return values as to preserve their original state, but this caused Segfaults in 2.7.2. Currently the object itself gets directly exposed, which allows it to be mutated outside of it's own scope. I think the ultimate solution here would be to deprecate usage of NIO::ByteBuffer for readables until it's in a more mature state or I git gud at C well enough to sort it out on my own..:(
  #
  # @param type [Symbol] the type of content to peek into [:readable, :writable]
  # @return [String] a snapshot of the payload
  def peek(type)
    case type
    when :writeable
      @writeable.dup if Message.validate(self, :peek_write)
    when :readable
      if Message.validate(self, :peek_read)
        @readable.is_a?(NIO::ByteBuffer) ? @readable.get : @readable
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
  # @param body [String, StringIO] the body for the Writable Message.
  def enable_writeable(body = '')
    # Initialize the writable content body.
    @writeable = body

    # Set access var for bit and byte writing.
    @access = :BYTE

    # Set the initial bit position for bit writing.
    @bit_position = 0

    # Define functions on the message instance.
    self.class.include(Writeable)

    # Update the message mode
    @mode[:writeable] = true
  end

  # Enables Readable functions for the Message. Under the hood, the Readable module is included, the initialize Message#header is created if it does not exist, then set and frozen as Readable Messages should not have modifiable headers.
  # @param body [String, StringIO] the body for the Readable Message.
  def enable_readable(body = '')
    # Freeze the readable header.
    @header.freeze

    # Initialize the readable payload.
    @readable = body

    # Define functions on the message instance.
    self.class.include(Readable)

    # Update the message mode
    @mode[:readable] = true
  end
end