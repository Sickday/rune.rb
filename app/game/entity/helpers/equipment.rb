# Copyright (c) 2020, Patrick W.
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

module RuneRb::Game::Entity::Helpers::Equipment

  # Shorthand slot assignment
  # @param value [RuneRb::Game::Item::Stack] the item to assign
  # @param slot [Integer] the destination slot.
  def []=(slot, value)
    @equipment[slot] = value
  end

  alias equip []=

  # Shorthand slot retrieval
  # @param slot [Integer] the slot to retrieve
  def [](slot)
    @equipment[slot]
  end

  # Un-equips an slot.
  # @param slot [Integer] un-equips a slot.
  def unequip(slot)
    @equipment[slot] = -1
  end

  private

  # Creates default equipment database.
  # @param data [Hash] database that should be contained in this Equipment.
  def setup_equipment(data = nil)
    @equipment = data || { 0 => -1, # Hat
                           1 => -1, # Cape
                           2 => -1, # Amulet
                           3 => -1, # Weapon
                           4 => -1,
                           5 => -1,
                           6 => -1,
                           7 => -1,
                           8 => -1,
                           9 => -1,
                           10 => -1,
                           11 => -1,
                           12 => -1,
                           13 => -1 }
  end

  # Initialize Equipment for the Context. Attempts to load equipment from serialized dump or create a new empty Equipment model for the context.
  def load_equipment
    if !@profile.equipment.nil? && !Oj.load(@profile.equipment).empty?
      restore_equipment
    else
      setup_equipment
    end
    update(:equipment)
    log(RuneRb::GLOBAL[:COLOR].green("Loaded Equipment for #{RuneRb::GLOBAL[:COLOR].yellow(@profile.name)}")) if RuneRb::GLOBAL[:DEBUG]
  end

  # Dumps the equipment of a context entity
  def dump_equipment
    @profile.update(equipment: Oj.dump(@equipment.to_hash, mode: :compat, use_as_json: true))
  end

  # Restores the equipment of the context
  def restore_equipment
    data = Oj.load(@profile[:equipment])
    parsed = {}.tap do |hash|
      data.each do |slot, stack|
        hash[slot.to_i] = -1
        next if stack == -1 || stack.nil?

        hash[slot.to_i] = RuneRb::Game::Item::Stack.restore(id: stack['id'].to_i, amount: stack['amount'].to_i)
      end
    end
    setup_equipment(parsed)
  end
end