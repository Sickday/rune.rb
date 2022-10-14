module RuneRb::Game::Entity::Helpers::Equipment
  include RuneRb::Utils::Logging

  # @!attribute [r] equipment
  # @return [Hash] the Equipment database for a context.
  attr :equipment

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
    @equipment = { HAT: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   CAPE: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   AMULET: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   WEAPON: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   CHEST: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   SHIELD: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   LEGS: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   GLOVES: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   BOOTS: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   RING: RuneRb::Game::Item::Constants::PLACEHOLDER,
                   ARROWS: RuneRb::Game::Item::Constants::PLACEHOLDER }
  end

  # Initialize Equipment for the Context. Attempts to load equipment from serialized dump or create a new empty Equipment model for the context.
  def load_equipment(first_login: false)
    first_login ? setup_equipment : restore_equipment
    log(COLORS.green("Loaded Equipment for #{COLORS.yellow(@profile.username)}")) unless ENV['RRB_DEBUG'].nil?
  end

  # Dumps the equipment of a context entity
  def dump_equipment
    @profile.items.update(equipment: Oj.dump(@equipment, mode: :compat))
  end

  # Restores the equipment of the context
  def restore_equipment
    data = Oj.load(@profile.items.equipment)
    if data.nil?
      setup_equipment
    else
      @equipment = {}.tap do |hash|
        data.each do |slot, stack|
          hash[slot.to_sym] = RuneRb::Game::Item::Stack.new(-1, 0)
          next if stack.nil? || stack == -1 || stack['id'] == -1

          hash[slot.to_sym] = RuneRb::Game::Item::Stack.restore(id: stack['id'].to_i, amount: stack['amount'].to_i)
        end
      end
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