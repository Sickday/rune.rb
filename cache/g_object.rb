module RuneRb::Cache::Definitions
  class GameObject
    attr_accessor :type
    attr :data, :archive

    Data = Struct.new(
        :aBool736,
        :name,
        :aInt744,
        :aInt746,
        :original_colors,
        :aInt749,
        :low_mem,
        :type,
        :aBool757,
        :aInt758,
        :child_ids,
        :aInt761,
        :aBool762,
        :aBool764,
        :aBool767,
        :aInt768,
        :cache_index,
        :aIntArr773,
        :aInt774,
        :aInt775,
        :aIntArr776,
        :description,
        :actions?,
        :aBool779,
        :aInt781,
        :modded_colors,
        :actions
    )

    def initialize(type = -1)
      @type = type
      @data = Data.new
      @cache_index = 0
      @data[:aIntArr773] = nil
      @data[:aIntArr776] = nil

      @data[:name] = nil
      @data[:description] = nil
      @data[:modded_colors] = nil
      @data[:original_colors] = nil

      @data[:aInt744] = 1
      @data[:aInt761] = 1
      @data[:aBool767] = true
      @data[:aBool757] = true
      @data[:actions?] = false
      @data[:aBool762] = false
      @data[:aBool764] = false

      @data[:aInt781] = -1
      @data[:aInt775] = 16
      @data[:actions] = nil
      @data[:aInt746] = -1
      @data[:aInt758] = -1
      @data[:aBool779] = true
      @data[:aInt768] = 0
      @data[:aBool736] = false

      @data[:aInt774] = -1
      @data[:aInt749] = -1
      @data[:child_ids] = nil
    end

    def buffer(string)
      raise "Unable to locate Cache files (data/world/object/#{string})" unless File.exist?("data/world/object/#{string}")

      buffer = []
      File.read("./data/world/object/#{string}").each_byte { |byte| buffer << byte }
      buffer
    rescue StandardError => e
      puts 'An error occurred generating buffer'
      puts e
      puts e.backtrace
    end

    def object_def(type)
      obj = @cache.detect { |object| object.type == type }
      return obj unless obj.nil?

      @cache_index = (@cache_index + 1) % 20
      class46 = @cache[@cache_index]
      class46.type = type
      buffer = @archive.retrieve(type)
      class46.read_values(RuneRb::Cache::PoorStreamExtended.new(buffer)) unless buffer.nil? || buffer.empty? || buffer.all?(&:nil?)
      class46
    end

    # @param stream [RuneRb::Cache::PoorStreamExtended]
    def read_values(stream)
      flag = -1
      loop do
        type = stream.next_ubyte
        break if type.zero?

        case type
        when 1
          length = stream.next_ubyte
          if length.positive?
            if @data[:aIntArr773].nil? || @data[:low_mem]
              @data[:aIntArr776] = Array.new(length)
              @data[:aIntArr773] = Array.new(length)
              length.times do |itr|
                @data[:aIntArr773][itr] = stream.next_uword
                @data[:aIntArr776][itr] = stream.next_ubyte
              end
            else
              stream.offset += length * 3
            end
          end
        when 2
          @data[:name] = stream.next_nstring
        when 5
          length = stream.next_ubyte
          if length.positive?
            if @data[:aIntArr773].nil? || @data[:low_mem]
              @data[:aIntArr776] = nil
              @data[:aIntArr773] = Array.new(length)
              length.times { |itr| @data[:aIntArr773][itr] = stream.next_uword }
            else
              stream.offset += length * 2
            end
          end
        when 14
          @data[:aInt744] = stream.next_ubyte
        when 15
          @data[:aInt761] = stream.next_ubyte
        when 17
          @data[:aBool767] = false
        when 18
          @data[:aBool757] = false
        when 19
          @data[:actions?] = stream.next_ubyte == 1
        when 21
          @data[:aBool762] = true
        when 23
          @data[:aBool764] = true
        when 24
          @data[:aInt781] = stream.next_uword
          @data[:aInt781] = -1 if @data[:aInt781] == 65535
        when 27
          next
        when 28
          @data[:aInt775] = stream.next_ubyte
        when 29, 39
          stream.next_byte
        when (30...39)
          @data[:actions] ||= Array.new(5, '')
          @data[:actions][type - 30] = stream.next_nstring
          @data[:actions?] = true
          @data[:actions][type - 30] = nil if @data[:actions][type - 30] == 'hidden'
        when 40
          length = stream.next_ubyte
          @data[:modded_colors] = Array.new(length)
          @data[:original_colors] = Array.new(length)
          length.times do |itr|
            @data[:modded_colors][itr] = stream.next_uword
            @data[:original_colors][itr] = stream.next_uword
          end
        when 41
          length = stream.next_ubyte
          stream.skip(length * 4)
        when 42
          length = stream.next_ubyte
          stream.skip(length)
        when 60
          @data[:aInt746] = stream.next_uword
        when 62 then nil
        when 64
          @data[:aBool779] = false
        when 65, 66, 67
          stream.next_uword
        when 68
          @data[:aInt758] = stream.next_uword
        when 69
          @data[:aInt768] = stream.next_ubyte
        when 70, 71, 72
          stream.next_word
        when 73
          @data[:aBool736] = true
        when 75
          stream.next_ubyte
        when 77, 92
          @data[:aInt774] = stream.next_uword
          @data[:aInt774] = -1 if @data[:aInt774] == 65535
          end_child = -1
          if type == 92
            end_child = stream.next_word
            end_child = -1 if end_child == 65535
          end

          @data[:child_ids] = []
          length = stream.next_ubyte
          length.times do |itr|
            @data[:child_ids][itr] = stream.next_uword
            @data[:child_ids][itr] = -1 if @data[:child_ids][itr] == 65535
          end
          @data[:child_ids][length + 1] = end_child
        when 78
          stream.skip(3)
        when 79
          stream.skip(5)
          length = stream.next_ubyte
          stream.skip(length * 2)
        when 81
          stream.skip(1)
        when 82, 88, 89, 90, 91, 94, 95, 96, 97
          next
        when 93
          stream.skip(2)
        when 249
          length = stream.next_ubyte
          length.times do |itr|
            skip = stream.next_ubyte == 1
            stream.skip(3)
            if skip
              stream.next_nstring
            else
              stream.skip(4)
            end
          end
        else
          puts "Unrecognized Object Config Type #{type}"
        end
      end
      return unless flag == -1

      @data[:actions?] = !@data[:aIntArr773].nil? && (@data[:aIntArr776].nil? || @data[:aIntArr776][0] == 10)
      @data[:actions?] = true if @data[:actions?].nil?
    end

    def load_config
      @archive = RuneRb::Cache::MemoryArchive.new(
          RuneRb::Cache::PoorStreamExtended.new(buffer('loc.dat')),
          RuneRb::Cache::PoorStreamExtended.new(buffer('loc.idx')))
      @cache = 20.times.inject([]) { |arr| arr << GameObject.new; arr }
    end

    def actions?
      @data[:actions?]
    end

    def name?
      !@data[:name?].nil? && @data[:name].length > 1
    end

    def solid
      @data[:aBool779]
    end

    def length_x
      @data[:aInt744]
    end

    def length_y
      @data[:aInt761]
    end

    def aBool767
      @data[:aBool767]
    end

    def shootable?
      @data[:aBool757]
    end
  end
end