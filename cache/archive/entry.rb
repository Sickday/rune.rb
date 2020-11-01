module Cache
  class ArchiveEntry
    attr :identifier

    def initialize(ident, buffer)
      @identifier = ident
      @buffer = buffer
    end

    def buffer
      @buffer.dup
    end
  end
end