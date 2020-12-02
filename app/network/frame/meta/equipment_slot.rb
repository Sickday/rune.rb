module RuneRb::Net::Meta
  # A single EquipmentSlot
  class EquipmentSlotsFrame < RuneRb::Net::MetaFrame

    # Called when a new EquipmentSlotFrame is created.
    def initialize(data)
      super(34, false, true)
      parse(data)
    end

    private

    # Parses the data and writes to the payload appropriately
    def parse(data)
      write_short(1688) # EquipmentForm ID
      data.each do |slot, slot_data|
        write_smart(slot.to_i)

        id = slot_data.is_a?(Integer) || slot_data.nil? ? -1 : slot_data.id
        amount = slot_data.is_a?(Integer) || slot_data.nil? ? 0 : slot_data.size

        write_short(id + 1)

        if amount > 254
          write_byte(0xFF)
          write_int(amount)
        else
          write_byte(amount)
        end
      end
    end
  end
end