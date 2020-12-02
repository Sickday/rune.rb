module RuneRb::Entity::Helpers::Inventory

  # Adds an item stack to the inventory at a specific slot if provided
  # @param item_stack [RuneRb::Item::Stack] the item stack to add
  # @param at [Integer] the slot at which to add the item (else, the next available slot is used.)
  def add_item(item_stack, at = nil)
    if at
      @inventory[:container].data[at] = item_stack
    else
      @inventory[:container].add(item_stack)
    end
  end

  # Removes an item with the specified parameters from the inventory container.
  # @param id [Integer] the id of the item to remove
  # @param amt [Integer] the amount of the item to remove
  def remove_item(id, amt = 1)
    @inventory[:container].remove(id, amt)
  end

  private

  # Initializes the inventory
  # @param data [Hash] data to initialize the inventory with.
  def setup_inventory(data = nil)
    @inventory = {
        container: RuneRb::Item::Container.new(28, false),
        weight: 0
    }
    data&.each { |slot, stack| @inventory[:container].data[slot] = stack }
  end

  # Initialize Inventory for the Context. Attempts to load inventory from serialized dump or create a new empty Inventory for the context
  def load_inventory
    if !@profile.inventory.nil? && !Oj.load(@profile.inventory).empty?
      restore_inventory
    else
      setup_inventory
    end
    update(:inventory)
    log(RuneRb::COL.green("Loaded Inventory for #{RuneRb::COL.yellow(@profile.name)}")) if RuneRb::DEBUG
  end

  # Dumps the inventory of a player.
  def dump_inventory
    @profile.update(inventory: Oj.dump(@inventory[:container].data.to_hash, mode: :compat, use_as_json: true))
  end

  # Restores the inventory of a player
  def restore_inventory
    data = Oj.load(@profile[:inventory])
    parsed = {}.tap do |hash|
      data.each do |slot, stack|
        hash[slot.to_i] = RuneRb::Item::Stack.restore(id: stack['id'].to_i, amount: stack['amount'].to_i) unless stack.nil?
      end
    end
    setup_inventory(parsed)
  end
end