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

  def setup_equipment
    @equipment = {
      HAT: RuneRb::Game::Item::Stack.new(-1, 0),
      CAPE: RuneRb::Game::Item::Stack.new(-1, 0),
      AMULET: RuneRb::Game::Item::Stack.new(-1, 0),
      WEAPON: RuneRb::Game::Item::Stack.new(-1, 0),
      CHEST: RuneRb::Game::Item::Stack.new(-1, 0),
      SHIELD: RuneRb::Game::Item::Stack.new(-1, 0),
      LEGS: RuneRb::Game::Item::Stack.new(-1, 0),
      GLOVES: RuneRb::Game::Item::Stack.new(-1, 0),
      BOOTS: RuneRb::Game::Item::Stack.new(-1, 0),
      RING: RuneRb::Game::Item::Stack.new(-1, 0),
      ARROWS: RuneRb::Game::Item::Stack.new(-1, 0)
    }
  end

  # Initialize Equipment for the Context. Attempts to load equipment from serialized dump or create a new empty Equipment model for the context.
  def load_equipment(first)
    first ? setup_equipment : restore_equipment
    log(RuneRb::GLOBAL[:COLOR].green("Loaded Equipment for #{RuneRb::GLOBAL[:COLOR].yellow(@profile.name)}")) if RuneRb::GLOBAL[:DEBUG]
  end

  # Dumps the equipment of a context entity
  def dump_equipment
    @profile.update(equipment: Oj.dump(@equipment.to_hash, mode: :compat, use_as_json: true))
  end

  # Restores the equipment of the context
  def restore_equipment
    data = Oj.load(@profile[:equipment])
    @equipment = {}.tap do |hash|
      data.each do |slot, stack|
        hash[slot.to_sym] = RuneRb::Game::Item::Stack.new(-1, -1)
        next if stack == -1 || stack.nil?

        hash[slot.to_sym] = RuneRb::Game::Item::Stack.restore(id: stack['id'].to_i, amount: stack['amount'].to_i)
      end
    end
  end
end