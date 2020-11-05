module RuneRb::Game
  class Inventory < RuneRb::Game::ItemContainer
    attr :weight

    # Called when a new Inventory is created
    def initialize
      super(28, false)
      @weight = 0
    end

    # Patch the parent class ItemContainer#add function to ensure weight is updated after item addition.
    def add(item_stack)
      super(item_stack)
      weight_update
    end

    # Patch the parent class ItemContainer#remove function to ensure weight is updated after item removal.
    def remove(id, amt = 1)
      super(id, amt)
      weight_update
    end

    def stack_count
      @data.inject(0) { |sum, slot_stack| sum += 1 if slot_stack.last; sum }
    end

    private

    # Updates the weight of the inventory
    def weight_update
      @weight = @data.inject(0) do |sum, slot_stack|
        sum += slot_stack.last.definition.weight if slot_stack.last
        sum
      end
    end
  end
end