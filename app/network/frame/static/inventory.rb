module RuneRb::Net::Static
  # A Context Mob's Inventory
  class ContextInventoryFrame < RuneRb::Net::MetaFrame
    # Called when a new ContextInventoryFrame is created
    # @param data [Hash] the data for the ContextInventoryFrame
    # @param length [Integer] the length of the inventory in slots.
    def initialize(data, length)
      super(53)
      parse(data, length)
    end

    private

    def parse(data, length)
      write_short(3214) # ContextInventoryForm ID
      write_short(length)
      data.each do |_slot_id, item_stack|
        id = item_stack.is_a?(Integer) || item_stack.nil? ? -1 : item_stack.id
        amount = item_stack.is_a?(Integer) || item_stack.nil? ? 0 : item_stack.size

        if amount > 254
          write_byte(255)
          write_int(amount, :STD, :INVERSE_MIDDLE)
        else
          write_byte(amount)
        end
        write_short(id + 1, :A, :LITTLE)
      end
    end
  end
end