module Cache::Constants
  # A count of archives in cache 0
  ARCHIVE_COUNT = 9

  # Size of a single chunk
  CHUNK_SIZE = 512

  # Size of a header
  HEADER_SIZE = 8

  # Size of a block
  BLOCK_SIZE = HEADER_SIZE + CHUNK_SIZE

  # Size of an index
  INDEX_SIZE = 6
end