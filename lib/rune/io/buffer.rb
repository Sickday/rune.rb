module RuneRb::IO
  class Buffer
    include RuneRb::Utils::Logging

    # @return [Boolean] is {bit_access} enabled?
    attr_reader :bit_access

    # @return [String] the access mode.
    attr_reader :mode

    # @return [StringIO] the data.
    attr_reader :data

    # Construct a new instance of {Buffer}.
    # @param mode [String] the mode for the buffer. ['r', 'w']
    # @param data [StringIO, String] the data.
    # @return [Buffer] the created instance.
    def initialize(mode, data: '')
      raise "Invalid mode for Buffer! Expecting: r, rn, w, rw Got: #{mode}" unless /(?i)r|n|w/.match?(mode)

      @data = data
      @mode = mode

      enable_readable if /(?i)r/.match?(mode)
      enable_writeable if /(?i)w/.match?(mode)
      enable_native_readable if /(?i)n/.match?(mode)

      self
    end

    # The length of the underlying data.
    # @return [Integer]
    def length
      @data.length
    end

    alias size length

    # Fetches a snapshot of the message payload content.
    # @return [String] a snapshot of the payload
    def peek
      @data.force_encoding(Encoding::BINARY)
    end

    alias snapshot peek

    # Push data directly to the {Buffer#data} object.
    # @param data [String] the data to write.
    def push(data = '')
      @data.concat(data) unless data.empty?
    end

    alias << push

    def inspect
      if @mode.include?('w')
        "[BufferMode:] #{@mode} || [BodyLength:] #{@data.length} || [BitAccess:] #{@bit_access} || [Payload:] #{hex}"
      else
        "[BufferMode:] #{@mode} || [BodyLength:] #{@data.length} || [Payload:] #{hex}"
      end
    end

    # @return [String] hex representation of the buffer's data.
    def hex
      peek.each_byte.inject(String.new) { |dest, byte| dest << "#{byte < 16 ? '0' : ''}#{byte.to_s(16)} " }.strip
    end

    private

    # Enables Writeable functions for the Message.
    def enable_writeable
      @bit_access = false
      @bit_position = 0
      singleton_class.include(RuneRb::IO::Helpers::Writeable)
    end

    # Enables Readable functions for the Message.
    def enable_readable
      singleton_class.include(RuneRb::IO::Helpers::Readable)
    end

    # Enables Native reading functions for the Message.
    def enable_native_readable
      singleton_class.include(RuneRb::IO::Helpers::ReadableNative)
    end

    # Mutates the value according to the passed mutation
    # @param value [Integer] the value to mutate
    # @param mutation [Symbol] the mutation to apply to the value.
    def mutate(value, mutation)
      case mutation
      when :STD then value
      when :ADD then value += 128
      when :NEG then value = -value
      when :SUB then value -= 128
      else mutate(value, :STD)
      end
      value
    end
  end
end
