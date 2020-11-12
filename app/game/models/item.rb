module RuneRb::Game
  # Represents a stack of items.
  class ItemStack
    attr :definition, :id
    attr_accessor :size

    # Called when a new ItemStack is created.
    def initialize(id, amount = 1)
      @id = id
      @definition = RuneRb::Database::Item[id]
      @size = amount
    end

    def to_json
      ItemStack.dump(self)
    end

    def inspect
      @definition.inspect
    end

    class << self
      def dump(stack)
        Oj.dump({ id: stack.id, amount: stack.size }, mode: :compat, use_as_json: true)
      end

      def restore(data)
        ItemStack.new(data[:id], data[:amount])
      end
    end
  end
end