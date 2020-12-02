module CacheRb::FS
  # An object representation of an index within the main_file_cache.dat file
  class Index

    attr :size

    attr :block

    # @param size [Integer] the size of the file
    # @param block [Integer] the first block of the file
    def initialize(size, block)
      @size = size
      @block = block
    end

    class << self
      # @param buffer [Array] the buffer to decode
      # @return [Index] the decoded index.
      def decode(buffer)
        raise ArgumentError if buffer.size != INDEX_SIZE

        size = ((buffer[0] & 0xFF) << 16) | ((buffer[1] & 0xFF) << 8) | (buffer[2] & 0xFF)
        block = ((buffer[3] & 0xFF) << 16) | ((buffer[4] & 0xFF) << 8) | (buffer[5] & 0xFF)
        Index.new(size, block)
      end


    end
  end
end