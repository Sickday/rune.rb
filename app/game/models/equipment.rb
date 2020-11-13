module RuneRb::Game
  class Equipment
    attr :data

    def initialize(data)
      @data = data || { slot_1: -1, slot_2: -1, slot_3: -1, slot_4: -1,
                        hat: -1, cape: -1, amulet: -1, shield: -1, legs: -1,
                        torso: -1, gloves: -1, boots: -1, ring: -1, arrows: -1,
                        plate_body?: nil, full_helm?: nil }
    end

    # Shorthand slot assignment
    # @param value [RuneRb::Game::ItemStack] the item to assign
    # @param slot [Symbol] the destination slot.
    def []=(value, slot)
      @data[slot] = value if @data.keys.include?(slot)
    end

    # Shorthand slot retrieval
    # @param slot [Symbol] the slot to retrieve
    def [](slot)
      @data[slot]
    end

    class << self
      include RuneRb::Types::Loggable

      # Attempts to unequip the item in the specified slot and add it to the player's inventory
      # @param from_slot [Symbol] the slot to unequip
      def unequip(equipment, from_slot, player)
        return unless equipment[from_slot]

        if player.inventory.add(equipment.data[from_slot])
          equipment[from_slot] = -1
        else
          player.session.write_text("You don't have enough space in your inventory to un-equip that item!")
        end
      end


      def dump(player)
        player.profile.appearance.update(equipment: Oj.dump(player.equipment.data.to_hash, mode: :compat, use_as_json: true))
        log RuneRb::COL.green("Dumped Equipment for #{RuneRb::COL.cyan(player.profile[:name])}!")
      end

      def restore(player)
        data = Oj.load(player.appearance[:equipment])
        log RuneRb::COL.red "Parsing: #{data.inspect}"
        parsed = {}.tap do |hash|
          data.each do |slot, stack|
            hash[slot.to_sym] = -1
            next if stack == -1 || stack.nil?

            hash[slot.to_sym] = RuneRb::Game::ItemStack.restore(id: stack['id'], amount: stack['amount'])
          end
        end
        log RuneRb::COL.green("Restored Equipment: #{RuneRb::COL.cyan(parsed.inspect)}")
        Equipment.new(parsed)
      end
    end
  end
end