module RuneRb::Game
  # Represents a stack of items.
  class ItemStack
    attr :definition
    attr_accessor :size

    # Called when a new ItemStack is created.
    def initialize(id, amount = 1)
      @definition = RuneRb::Database::Item[id]
      @size = amount
    end
  end
end