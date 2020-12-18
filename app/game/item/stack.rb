module RuneRb::Game::Item
  # Represents a stack of items.
  class Stack
    attr :definition, :id
    attr_accessor :size

    # Called when a new ItemStack is created.
    # @param id [Integer] the id of the Item
    # @param amount [Integer] the initial amount of the stack.
    def initialize(id, amount = 1)
      @id = id
      @definition = RuneRb::System::Database::Item[id]
      @size = amount
    end

    # Returns serialized dump of this Stack.
    # @return [String] A dump of this Stack
    def to_json(*_args)
      RuneRb::Game::Item::Stack.dump(self)
    end

    # An inspection of the Stack's definition.
    def inspect
      @definition.inspect
    end

    class << self
      # Returns a serialized dump of the passed Stack object.
      # @param stack [RuneRb::Game::Item::Stack] the Stack to dump
      def dump(stack)
        Oj.dump({ id: stack.id, amount: stack.size }, mode: :compat, use_as_json: true)
      end

      # Restores a serialized dump of a Stack object.
      # @param data [Hash] a serialized dump
      def restore(data)
        RuneRb::Game::Item::Stack.new(data[:id], data[:amount])
      end
    end
  end
end