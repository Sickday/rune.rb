module RuneRb::Entity
  class Equipment
    attr :data

    # Called when an Equipment is created
    # @param data [Hash] data that should be contained in this Equipment.
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
    # @param value [RuneRb::Game::Stack] the item to assign
    # @param slot [Integer] the destination slot.
    def []=(slot, value)
      @data[slot] = value
    end

    alias equip []=

    # Shorthand slot retrieval
    # @param slot [Integer] the slot to retrieve
    def [](slot)
      @data[slot]
    end

    # Un-equips an slot.
    # @param slot [Integer] un-equips a slot.
    def unequip(slot)
      @data[slot] = -1
    end

    class << self

      # Dumps the equipment of an entity
      # @param player [RuneRb::Entity::Mob] the entity whose equipment will be dumped.
      def dump(player)
        player.profile.update(equipment: Oj.dump(player.equipment.data.to_hash, mode: :compat, use_as_json: true))
      end

      # Restores the equipment of an entity
      # @param player [RuneRb::Entity::Mob] the entity whose equipment will be restored.
      def restore(player)
        data = Oj.load(player.profile[:equipment])
        parsed = {}.tap do |hash|
          data.each do |slot, stack|
            hash[slot.to_i] = -1
            next if stack == -1 || stack.nil?

            hash[slot.to_i] = RuneRb::Game::Item::Stack.restore(id: stack['id'], amount: stack['amount'])
          end
        end
        RuneRb::Entity::Equipment.new(parsed)
      end
    end
  end
end