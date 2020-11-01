module Cache::Decode
  class ObjectDecoder

    attr :fs

    #
    # @param file_system [Cache::IndexedFS] - the indexed file system
    def initialize(file_system)
      @fs = file_system
    end

    def execute
      config = fs.archive(0, 2)
      data = config.entry_for('loc.dat')
      idx = config.entry_for('loc.idx')

      count = idx.next_short
      index = 2
      indicies = Array.new(count)
      count.times do |i|
        indicies[i] = index
        index += idx.next_short
      end

      defs = Array.new(count)
      count.times do |i|
        defs[i] = decode(data)
      end

    end
  end
end