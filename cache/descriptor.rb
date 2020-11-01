module Cache
  class Descriptor
    attr :type, :file

    # Called when a new Descriptor is created.
    # @param type
    # @param file [Integer] the file ID.
    def initialize(type, file)
      @type, @file = type, file
    end

    def eql?(other)
      @type == other.type && file == other.file
    end

    def hash
      @file * Cache::Constants::ARCHIVE_COUNT + @type
    end
  end
end