module Cache
  class Index

    attr :block, :size


    def initialize(size, block)
      @size, @block = size, block
    end

    def self.decode(buffer)
      raise 'Incorrect buffer length!' unless buffer.length == Cache::Constants::INDEX_SIZE

      size = (buffer[0] & 0xFF) << 16 | (buffer[1] & 0xFF) << 8 | buffer[2] & 0xFF
      block = (buffer[3] & 0xFF) << 16 | (buffer[4] & 0xFF) << 8 | buffer[5] & 0xFF
      Cache::Index.new(size, block)
    end
  end
end