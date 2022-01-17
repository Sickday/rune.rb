module RuneRb::Game::Entity::Helpers::Inventory
  include RuneRb::Utils::Logging

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

  # Initializes the <@inventory> object. Passed data is used to setup the inventory if present.
  # @param data [Hash] database to initialize the inventory with.
  def setup_inventory(data = nil)
    @inventory = {
      container: RuneRb::Game::Item::Container.new(28, stackable: false),
      weight: 0
    }
    @inventory[:container].from(data) unless data.nil? || !data.is_a?(Hash)
  end

  # Initialize Inventory for the Context. Attempts to load inventory from serialized dump or create a new empty Inventory for the context
  def load_inventory(first_login: true)
    first_login ? setup_inventory : restore_inventory
    log COLORS.green("Loaded Inventory for #{COLORS.yellow(@profile.username)}") if RuneRb::GLOBAL[:ENV].debug
  end

  # Deserializes inventory data to the inventory column of the player's <@profile> dataset.
  def dump_inventory
    @profile.update(inventory: Oj.dump(@inventory[:container].data.to_hash, mode: :compat, use_as_json: true))
  end

  # Attempts to reconstruct the <@inventory> object with data in the player's inventory column from the <@profile> dataset. If the data is not parsable, a new empty inventory is created.
  def restore_inventory
    # Deserialize raw profile data
    data = Oj.load(@profile.items.inventory)

    # Parse the deserialized data into a hash container.
    parsed = {}.tap do |hash|
      data.each do |slot, stack|
        hash[slot.to_i] = if stack.nil?
                            RuneRb::Game::Item::Stack.restore(id: -1, amount: 0)
                          else
                            RuneRb::Game::Item::Stack.restore(id: stack['id'].to_i, amount: stack['amount'].to_i)
                          end
      end
    end

    # Setup the inventory with the parsed data container.
    setup_inventory(parsed)
    dump_inventory
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