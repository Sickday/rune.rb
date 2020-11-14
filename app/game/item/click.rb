module RuneRb::Game::Item
  class Click
    class << self
      include RuneRb::Types::Loggable
      def parse_action(type, assets)
        case type
        when :first_action then parse_first_action(assets[:context], assets[:frame])
        when :switch_item then parse_switch_item(assets[:context], assets[:frame])
        else
          err "Unrecognized action type: #{type}"
        end
      end

      def parse_option(type, assets)
        case type
        when :fifth_option then parse_fifth_option(assets[:context], assets[:frame])
        else
          err "Unrecognized option type: #{type}"
        end
      end


      private

      def parse_switch_item(context, frame)
        interface = frame.read_short(false, :A, :LITTLE)
        inserting = frame.read_byte(false, :C) # This will matter when bank is implemented. TODO: impl bank
        old_slot = frame.read_short(false, :A, :LITTLE)
        new_slot = frame.read_short(false, :STD, :LITTLE)
        log "Got interface #{interface}"
        case interface
        when 3214
          if old_slot >= 0 &&
              new_slot >= 0 &&
              old_slot <= context.inventory.capacity &&
              new_slot <= context.inventory.capacity
            context.inventory.swap(old_slot, new_slot)
            context.schedule(:inventory)
          end
        else
          err "Unrecognized Interface ID: #{interface} for SwitchItem"
          nil
        end
      end

      def parse_fifth_option(context, frame)
        item_id = frame.read_short(false, :A)
        interface = frame.read_short(false)
        slot = frame.read_short(false, :A)
        log "Got interface #{interface}"
        case interface
        when 3214
          return unless context.inventory.has?(item_id)

          ## TODO: Implement and call create ground item
          context.inventory.remove(item_id)
          context.schedule(:inventory)
        else
          err "Unrecognized Interface ID: #{interface} for FifthOptionClick"
        end
      end

      def parse_first_action(context, frame)
        interface = frame.read_short(false, :A)
        slot = frame.read_short(false, :A)
        item_id = frame.read_short(false, :A)
        log "Got interface #{interface}"
        case interface
        when 3214
          if context.inventory.add(RuneRb::Game::Item::Stack.new(item_id))
            context.equipment.unequip(slot)
            context.schedule(:equipment)
          else
            context.session.write_text("You don't have enough space in your inventory to do this.")
          end
        else
          err "Unrecognized Interface ID: #{interface} for FirstActionClick"
        end
      end
    end
  end
end