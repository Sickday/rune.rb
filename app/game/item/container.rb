module RuneRb::Game::Item
  # A container of ItemStacks.
  class Container
    include RuneRb::Utils::Logging

    # Internal container object for ItemStacks
    attr :data

    # Maximum number of slots that can be filled in this container.
    attr :limit

    # Constructs a new Container.
    # @param capacity [Integer] the capacity of the Container
    # @param stackable [Boolean] should all ItemStacks in the Container be stackable?
    def initialize(capacity, stackable: false)
      @stackable = stackable
      @limit = capacity
      empty!
    end

    # Removes the item at the specified slot.
    # @param slot [Integer] the slot to remove at.
    def remove_at(slot)
      @data[slot] = nil
    end

    # Attempts to add an ItemStack to the container
    # @param item_stack [RuneRb::Game::Item::Stack] the Stack to add
    def add(item_stack)
      if item_stack.definition[:stackable] || @stackable
        if has?(item_stack.definition.id) && (item_stack.size + @data[slot_for(item_stack.definition.id)].size) < RuneRb::Game::Item::MAX_SIZE
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
      from += 1
      to += 1
      old = @data[from] if @data[from]
      new = @data[to] if @data[to]
      @data[from] = new
      @data[to] = old
    end

    # Attempts to remove a specified amount of items from the container
    # @param id [Integer] the item ID of the item to remove
    # @param amt [Integer] the amount to remove.
    def remove(id, amt = 1)
      slot = slot_for(id)
      if RuneRb::System::Database::Item[id][:stackable] || @stackable
        (@data[slot].size - amt) < 1 ? @data[slot] = nil : @data[slot].size -= amt
        true
      else
        until amt.zero?
          @data[slot_for(id)] = nil
          amt -= 1
        end
        true
      end
    end

    def from(data)
      @data = data if data.is_a? Hash
    end

    # Checks if the container has an entry with the specified ID and optional amount.
    # @param id [Integer] the ID of the item
    # @param at [Integer] an optional slot specifier
    # @param amt [Integer] the amount of the item
    # @return [Boolean] true if the container has an entry where the specified ID matches and the ItemStack size is greater than or equal to the specified amount.
    def has?(id, at = nil, amt = 1)
      if at
        !@data[at].nil? && @data[at].id == id && @data[at].size >= amt
      else
        @data.any? do |_slot, stack|
          next if stack.nil?

          ((stack.definition.id == id) && (stack.size >= amt))
        end
      end
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
      string = "\n"
      string << @data.inject('') do |str, values|
        itr += 1
        str << "\tS#{values[0]}:#{values[1]&.definition&.name} x #{values[1]&.size}\t|"
        str << "\n" if (itr % 4).zero?
        str
      end
      string
    end

    private

    # Is the Container stackable?
    attr :stackable

    # Retrieves the first slot for which an ItemStack with the specified ID matches
    # @param id [Integer] the item ID.
    def slot_for(id)
      @data.detect do |_slot, stack|
        next if stack.nil?

        stack.definition.id == id
      end.first
    end

    # Retrieves the next available slot in the inventory by checking for the first slot with a nil value
    # @return [Array] slot database for the first slot where the ItemStack is nil or does not exist
    def next_slot
      @data.detect { |_slot, stack| stack.nil? }
    end
  end
end

# Copyright (c) 2021, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.