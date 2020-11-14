module RuneRb::Game::Containers
  class Inventory < RuneRb::Game::Item::Container
    attr :weight, :data

    # Called when a new Inventory is created
    def initialize(data = nil)
      super(28, false)
      update_with(data) if data
      @weight = 0
    end

    # Patch the parent class Container#add function to ensure weight is updated after item addition.
    def add(item_stack, at = nil)
      if at
        @data[at] = item_stack
      else
        super(item_stack)
      end
      #weight_update
    end

    # Patch the parent class ItemContainer#remove function to ensure weight is updated after item removal.
    def remove(id, amt = 1)
      super(id, amt)
      #weight_update
    end

    def stack_count
      @data.inject(0) { |sum, slot_stack| sum += 1 if slot_stack.last; sum }
    end

    # @return [Integer] the capacity of the inventory
    def capacity
      @limit
    end

    private

    # Updates the weight of the inventory
    def weight_update
      @weight = @data.inject(0) do |sum, slot_stack|
        sum += slot_stack.last.definition.weight if slot_stack.last
        sum
      end
    end

    def update_with(inventory_data)
      inventory_data.each { |slot, stack| @data[slot] = stack }
    end

    class << self

      # Dumps the inventory of a player.
      # @param player [RuneRb::Entity::Context] the player whose inventory is being dumped
      def dump(player)
        player.profile.update(inventory: Oj.dump(player.inventory.data, mode: :compat, use_as_json: true))
      end

      # Restores the inventory of a player
      # @param player [RuneRb::Entity::Context] the player whose inventory is being restored.
      def restore(player)
        data = Oj.load(player.profile[:inventory])
        parsed = {}.tap do |hash|
          data.each do |slot, stack|
            hash[slot.to_i] = RuneRb::Game::Item::Stack.restore(id: stack['id'], amount: stack['amount']) unless stack.nil?
          end
        end
        RuneRb::Game::Containers::Inventory.new(parsed)
      end
    end
  end
end