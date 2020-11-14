module RuneRb::Cache
  class MemoryArchive

    INDEX_DATA_CHUNK_SIZE = 12

    # @param cache [RuneRb::Cache::PoorStream, RuneRb::Cache::PoorStreamExtended]
    # @param index [RuneRb::Cache::PoorStream, RuneRb::Cache::PoorStreamExtended]
    def initialize(cache, index)
      @cache = cache
      @index = index
    end

    def retrieve(data_index)
      return nil if @index.length < (data_index * INDEX_DATA_CHUNK_SIZE)

      @index.to(data_index * INDEX_DATA_CHUNK_SIZE)
      file_offset = @index.next_long
      file_size = @index.next_int

      @cache.to(file_offset)
      @cache.read(file_size)
    rescue StandardError => e
      puts "An error occurred retrieving index #{data_index}"
      puts e
      puts e.backtrace
    end

    def content_size
      @index.size / INDEX_DATA_CHUNK_SIZE
    end
  end
end