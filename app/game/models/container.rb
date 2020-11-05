module RuneRb::Game
  # A container of ItemStacks.
  class ItemContainer

    # Called when a new ItemContainer is created.
    # @param capacity [Integer] the capacity of the ItemContainer
    # @param stackable [Boolean] should all ItemStacks in the ItemContainer be stacked?
    def initialize(capacity, stackable = false)
      @stackable = stackable
      @limit = capacity
      empty!
    end

    # Attempts to add an ItemStack to the container
    # @param item_stack [RuneRb::Game::ItemStack] the ItemStack to add
    def add(item_stack)
      if item_stack.definition[:stackable] || @stackable
        if has?(item_stack.definition.id) && (item_stack.size + @data[slot_for(item_stack.definition.id)].size) < RuneRb::Game::MAX_ITEMS
          slot = slot_for(item_stack.definition.id)
          @data[slot].size += item_stack.size
        else
          slot = next_slot&.first
          return false if slot.nil? # Inventory full

          @data[slot] = item_stack
        end
      else
        slot = next_slot&.first
        return false if slot.nil? # Inventory full

        @data[slot] = item_stack
      end
      true
    end

    # Attempts to swap item stacks from one slot to another
    # @param from [Integer] the slot number to swap from
    # @param to [Integer] the slot number to swap to
    def swap(from, to)
      @data[from], @data[to] = @data[to], @data[from]
    end

    # Attempts to remove a specified amount of items from the container
    # @param id [Integer] the item ID of the item to remove
    # @param amt [Integer] the amount to remove.
    def remove(id, amt = 1)
      slot = slot_for(id)
      if RuneRb::Database::Item[id][:stackable] || @stackable
        (@data[slot].size - amt) < 1 ? @data[slot] = nil : @data[slot].size -= amt
        true
      else
        until amt == 0
          @data[slot_for(id)] = nil
          amt -= 1
        end
        true
      end
    end

    # Checks if the container has an entry with the specified ID and optional amount.
    # @param id [Integer] the ID of the item
    # @param amt [Integer] the amount of the item
    # @return [Boolean] true if the container has an entry where the specified ID matches and the ItemStack size is greater than or equal to the specified amount.
    def has?(id, amt = 1)
      @data.any? { |_slot, stack| ((stack&.definition&.id == id) && (stack.size >= amt)) }
    end

    # Returns a sum of the size of each ItemStack where the ID is equal to the specified id.
    # @param id [Integer]
    def count(id)
      @data.inject(0) do |itr, slot_stack|
        itr += slot_stack[1]&.size if slot_stack[1]&.definition&.id == id
        itr
      end
    end

    # Returns the ItemStack at the given slot
    # @param slot [Integer] the slot to check
    def at(slot)
      @data[slot]
    end

    # Clears all slots.
    def empty!
      @data = {}.tap { |hash| (1..@limit).each { |itr| hash[itr] = nil } }
    end

    def inspect
      itr = 0
      @data.inject('') do |str, values|
        itr += 1
        str << "\tS#{values[0]}:#{values[1]&.definition&.name}x#{values[1]&.size}\t|"
        str << "\n" if itr % 4 == 0
        str
      end
    end

    private

    attr :data, :stackable, :limit

    # Retrieves the first slot for which an ItemStack with the specified ID matches
    # @param id [Integer] the item ID.
    def slot_for(id)
      @data.detect do |_slot, stack|
        stack&.definition&.id == id
      end.first
    end

    # Retrieves the next available slot in the inventory by checking for the first slot with a nil value
    # @return [Array] slot data for the first slot where the ItemStack is nil or does not exist
    def next_slot
      @data.detect { |_slot, stack| stack.nil? }
    end
  end
end