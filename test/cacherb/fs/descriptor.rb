module CacheRb::FS
  class Descriptor
    # Create the descriptor
    # @param type [Integer] the file type
    # @param file [Integer] the file id
    def initialize(type, file)
      @type = type
      @file = file
    end
  end
end