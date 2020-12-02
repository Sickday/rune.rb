module RuneRb::Net::Static
  # A single EquipmentSlot
  class EquipmentSlotsFrame < RuneRb::Net::MetaFrame

    # Called when a new EquipmentSlotFrame is created.
    def initialize(slot, data)
      super(34, false, true)
      parse(slot, data)
    end

    private

    # Parses the data and writes to the payload appropriately
    def parse(slot, data)
      write_short(1688) # EquipmentForm ID
      write_smart(slot)
      if !data == -1 && !data.nil?
        write_short(data.id + 1)
        if data.size > 254
          write_byte(0xff)
          write_int(data.size)
        else
          write_byte(data.size)
        end
      else
        write_byte(-1)
      end
    end
  end
end