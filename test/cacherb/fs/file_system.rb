module CacheRb::FS
  class FileSystem

    def initialize(base, read_only)
      @read_only = read_only
      @indicies = Array.new(256)
      detect_layout(base)
    end

    def detect_layout(base)
      idx_count = 0
      @indicies.length.times do |idx|
        path = base + '/main_file_cache.idx' + idx
        if File.exists?(path)
          f = File.open(path)
          idx_count += 1
          @indicies[idx] = f
        end
      end

      raise "No index file(s) found!" unless idx_count > 0

      if File.exists?(base + '/main_file_cache.dat')
        @data = File.open(base + '/main_file_cache.dat')
      elsif File.exists?(base + '/main_file_cache.dat2')
        @data = File.open(base + '/main_file_cache.dat2')
      else
        raise "No data file present in base directory!"
      end
    end

    # retrieves the index of a file
    # @param descriptor [CacheRb::FS::Descriptor] the descriptor pointing to the file
    def index(descriptor)
      idx = descriptor.type
      raise IndexError if idx < 0 || idx > @indicies.length

      buffer = ''
      idx_file = @indicies[idx]
      ptr = descriptor.file * INDEX_SIZE

      if ptr >= 0 && idx_file.length >= (ptr + INDEX_SIZE)
        idx_file.seek(ptr, IO::SEEK_SET)
        buffer << idx_file.read
      end

      Index.decode(buffer.unpack('c*'))
    end
  end
end