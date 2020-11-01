module Cache
  class Archive
    include RuneRb::Patches::StringOverrides

    def initialize(entries)
      @entries = entries
    end

    def self.decode(buffer)
      extracted_size = (buffer.next_short & 0xFFFF) << 8 | buffer.next_byte & 0xFF
      size = (buffer.next_short & 0xFFFF) << 8 | buffer.next_byte & 0xFF
      extracted = false
      if size != extracted_size
        compressed = ''
        size.times { compressed << buffer.next_byte }
        decompressed = Bzip2::FFI::Reader.read(StringIO.new(compressed))
        extracted = true
      end

      entry_count = buffer.next_short & 0xFFFF
      identifiers = Array.new(entry_count)
      extracted_sizes = Array.new(entry_count)
      sizes = Array.new(entry_count)
      entry_count.times do |entry|
        identifiers[entry] = buffer.next_int
        extracted_sizes[entry] = (buffer.next_short & 0xFFFF) << 8 | buffer.next_byte & 0xFF
        sizes[entry] = (buffer.next_short & 0xFFFF) << 8 | buffer.next_byte & 0xFF
      end

      entries = Array.new(entry_count)
      entry_count.times do |entry|
        entry_buffer = ''

        if !extracted
          compressed = ''
          sizes[entry].times { compressed << buffer.next_byte }
          entry_buffer = Bzip2::FFI::Reader.read(StringIO.new(compressed))
        else
          extracted_sizes[entry].times { entry_buffer << buffer.next_byte }
        end

        entries[entry] = Cache::ArchiveEntry.new(identifiers[entry], entry_buffer)
      end

      Cache::Archive.new(entries)
    end

    def entry_for(name)
      hash = to_h(name)
      @entries.detect { |entry| entry.identifier == hash }
    end

    def to_h(string)
      string.upcase!.chars.reduce(0) { |hash, char| hash * 61 + char.ord - 32 }
    end
  end
end