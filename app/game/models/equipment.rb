module RuneRb::Game
  class Equipment
    attr :data

    def initialize(data = nil)
      @data = data || { 0 => -1, # Hat
                        1 => -1, # Cape
                        2 => -1, # Amulet
                        3 => -1, # Weapon
                        4 => -1,
                        5 => -1,
                        6 => -1,
                        7 => -1,
                        8 => -1,
                        9 => -1,
                        10 => -1,
                        11 => -1,
                        12 => -1,
                        13 => -1 }
    end

    # Shorthand slot assignment
    # @param value [RuneRb::Game::ItemStack] the item to assign
    # @param slot [Integer] the destination slot.
    def []=(slot, value)
      puts "writing #{value} to #{slot}"
      @data[slot] = value
      puts @data.inspect
    end

    # Shorthand slot retrieval
    # @param slot [Integer] the slot to retrieve
    def [](slot)
      @data[slot]
    end

    class << self
      include RuneRb::Types::Loggable

      def dump(player)
        player.profile.appearance.update(equipment: Oj.dump(player.equipment.data.to_hash, mode: :compat, use_as_json: true))
        log RuneRb::COL.green("Dumped Equipment for #{RuneRb::COL.cyan(player.profile[:name])}!")
      end

      def restore(player)
        data = Oj.load(player.appearance[:equipment])
        log RuneRb::COL.red "Parsing: #{data.inspect}"
        parsed = {}.tap do |hash|
          data.each do |slot, stack|
            hash[slot.to_i] = -1
            next if stack == -1 || stack.nil?

            hash[slot.to_i] = RuneRb::Game::ItemStack.restore(id: stack['id'], amount: stack['amount'])
          end
        end
        log RuneRb::COL.green("Restored Equipment: #{RuneRb::COL.cyan(parsed.inspect)}")
        Equipment.new(parsed)
      end
    end
  end
end