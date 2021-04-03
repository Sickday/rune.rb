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

module RuneRb::Game::Entity::Helpers::Inventory

  # Adds an item stack to the inventory at a specific slot if provided
  # @param item_stack [RuneRb::Game::Item::Stack] the item stack to add
  # @param at [Integer] the slot at which to add the item (else, the next available slot is used.)
  def add_item(item_stack, at = nil)
    if at
      @inventory[:container].data[at] = item_stack
    else
      @inventory[:container].add(item_stack)
    end
  end

  # Removes an item with the specified parameters from the inventory container.
  # @param id [Integer] the id of the item to remove
  # @param amt [Integer] the amount of the item to remove
  def remove_item(id, amt = 1)
    @inventory[:container].remove(id, amt)
  end

  private

  # Initializes the inventory
  # @param data [Hash] database to initialize the inventory with.
  def setup_inventory(data = nil)
    @inventory = {
        container: RuneRb::Game::Item::Container.new(28, stackable: false),
        weight: 0
    }
    data&.each { |slot, stack| @inventory[:container].data[slot] = stack }
  end

  # Initialize Inventory for the Context. Attempts to load inventory from serialized dump or create a new empty Inventory for the context
  def load_inventory
    if !@profile.inventory.nil? && !Oj.load(@profile.inventory).empty?
      restore_inventory
    else
      setup_inventory
    end
    log(RuneRb::GLOBAL[:COLOR].green("Loaded Inventory for #{RuneRb::GLOBAL[:COLOR].yellow(@profile.name)}")) if RuneRb::GLOBAL[:DEBUG]
  end

  # Dumps the inventory of a player.
  def dump_inventory
    @profile.update(inventory: Oj.dump(@inventory[:container].data.to_hash, mode: :compat, use_as_json: true))
  end

  # Restores the inventory of a player
  def restore_inventory
    data = Oj.load(@profile[:inventory])
    parsed = {}.tap do |hash|
      data.each do |slot, stack|
        hash[slot.to_i] = RuneRb::Game::Item::Stack.restore(id: stack['id'].to_i, amount: stack['amount'].to_i) unless stack.nil?
      end
    end
    setup_inventory(parsed)
  end
end