module Cache
  class IndexedFS

    def initialize(path, read_only)
      @read_only = read_only
      # Already decoded archives
      @cache = {}
      # Index files
      @indicies = Array.new(256)
      check_layout(path)
    end

    def close
      @data&.close
    end

    def archive(type, file)
      desc = Cache::Descriptor.new(type, file)
      cached = @cache[desc]
      if cached
        cached = Cache::Archive.decode(file_for(desc))
        @cache[desc] = cached
      end

      cached
    end

    def crcs
      return @crcs if @crcs

      @crcs ||= []
      tbl = crc_tbl
      @crcs << tbl.next_int until tbl.empty?
      @crcs
    end

    # Returns the crc table for the indexedfs
    def crc_tbl
      raise 'Unable to get CRC table from writable file system' unless @read_only

      @crc_table&.dup

      archives = file_count(0)-
      hash = 1234
      crcs = Array.new(archives)
      crc32 = Digest::CRC32.new
      crcs.length.times do |index|
        crc32.reset

        buffer = file_from(0, index)
        crc32.update(buffer)
        crcs[index] = crc32.finish
      end

      buffer = ''
      crcs.each do |crc|
        hash = (hash << 1) + crc
        buffer << [crc].pack('l') # As integer
      end

      buffer << [hash].pack('l')

      @crc_table = buffer.freeze
      @crc_table.dup
    end

    def file_from(type, file)
      file_for(Cache::Descriptor.new(type, file))
    end

    def file_for(descriptor)
      index = index(descriptor)
      buffer = ''

      pos = index.block * Cache::Constants::BLOCK_SIZE
      read = 0
      size = index.size
      blocks = size / Cache::Constants::CHUNK_SIZE
      blocks += 1 if size % Cache::Constants::CHUNK_SIZE != 0

      blocks.times do |block|
        header = ''
        @data.seek(pos)
        header << @data.read

        pos += Cache::Constants::HEADER_SIZE

        next_file = (header[0] & 0xFF) << 8 | header[1] & 0xFF
        current_chunk = (header[2] & 0xFF) << 8 | header[3] & 0xFF
        next_block = (header[4] & 0xFF) << 16 | (header[5] & 0xFF) << 8 | header[6] & 0xFF
        next_type = header[7] & 0xFF

        raise "Chunk ID Mismatch! Expected: #{block}, Got: #{current_chunk}" unless block == current_chunk

        chunk_size = size - read
        chunk_size = chunk_size > Cache::Constants::CHUNK_SIZE ? Cache::Constants::CHUNK_SIZE : chunk_size

        chunk = ''
        @data.seek(pos)
        chunk << @data.read

        buffer << chunk
        read += chunk_size
        pos = next_block * Cache::Constants::BLOCK_SIZE

        if size > read
          raise 'File type mismatch!' if next_type != descriptor.type + 1
          raise 'File ID mismatch' if next_file != descriptor.file
        end
      end
      buffer
    end

    def check_layout(path)
      count = 0
      @indicies.length.times do |index|
        idx = File.open(path + 'main_file_cache.idx' + index, @read_only ? 'r' : 'rw')
        if File.exist?(idx)
          count += 1
          @indicies[index] = idx
        end
      end

      raise "No index file(s) found in #{path}" if count <= 0
      raise 'No data file found (main_file_cache.dat)' unless File.exist?(path + 'main_file_cache.dat')

      @data = File.open(path + 'main_file_cache.dat', @read_only ? 'r' : 'rw')
    end

    # @return [Integer] the number of files with the specified type?
    def file_count(type)
      raise 'Supplied type is out of bounds' unless @indicies[type]

      file = @indicies[type]
      file.size / Cache::Constants::INDEX_SIZE
    end

    # @return [Index] returns an Index object for the provided descriptor
    def index(descriptor)
      index = descriptor.type
      raise 'Descriptor type is out of bounds' unless @indicies[index]

      buffer = ''
      idx = @indicies[index]
      pos = descriptor.file * Cache::Constants::INDEX_SIZE
      raise 'Could not locate file index.' unless (pos >= 0) && (idx.size >= (pos + Cache::Constants::INDEX_SIZE))

      idx.seek(pos)
      buffer << idx.read
      Cache::Index.decode(buffer)
    end
  end
end