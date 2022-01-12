module RuneRb::Network
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
    def initialize(mode, data: StringIO.new)
      raise "Invalid mode for Buffer! Expecting: r, rn, w, rw Got: #{mode}" unless /(?i)r|n|w/.match?(mode)

      @data = data.is_a?(String) ? StringIO.new(data) : data
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

    # Moves the cursor to the 0th position
    def rewind
      @data.rewind
    end

    # Sets the value at a specific position of the {Buffer}
    # @param position [Integer] the position to set the value at
    # @param value [Integer] the value to set
    # @param replace [Boolean] replace the old value?
    def at(position, value, replace: true)
      old = pos
      pos = position - 1
      @data << value
      @data.slice(pos + 1) if replace
      pos = old
    end

    # The amount of data remaining in the buffer.
    # @return [Integer]
    def remaining
      position - length
    end

    # The current position of the cursor
    # @return [Integer]
    def position
      @data.pos
    end

    alias pos position

    # Sets the cursor position
    # @param value [Integer] the offset position for the cursor.
    def position=(value)
      @data.pos = value
    end

    alias pos= position=

    # Fetches a snapshot of the message payload content.
    # @return [String] a snapshot of the payload
    def peek
      @data.string.force_encoding(Encoding::BINARY)
    end

    alias snapshot peek

    # Push data directly to the {Buffer#data} object.
    # @param data [String] the data to write.
    # @param rewind_cursor [Boolean] should the cursor be rewound to the 0th position?
    def push(data = '', rewind_cursor: false, socket: nil)
      @data << data unless data.empty?
      socket.read_nonblock(5192, @data) unless socket.nil?
      rewind if rewind_cursor
    end

    alias << push

    def inspect
      if @mode.include?('w')
        "[BufferMode:] #{@mode} || [BodyLength:] #{@data.length} || [BitAccess:] #{@bit_access}"
      else
        "[BufferMode:] #{@mode} || [BodyLength:] #{@data.length}"
      end
    end

    private

    # Enables Writeable functions for the Message.
    def enable_writeable
      @bit_access = false
      @bit_position = 0
      self.singleton_class.include(RuneRb::Network::Helpers::Writeable)
    end

    # Enables Readable functions for the Message.
    def enable_readable
      self.singleton_class.include(RuneRb::Network::Helpers::Readable)
    end

    # Enables Native reading functions for the Message.
    def enable_native_readable
      self.singleton_class.include(RuneRb::Network::Helpers::NativeReadable)
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
