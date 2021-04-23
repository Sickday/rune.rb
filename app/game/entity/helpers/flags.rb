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

# Functions to toggle, load and reset update flags for an Entity.
module RuneRb::Game::Entity::Helpers::Flags
  # @return [Hash] a collection of flags to observe when constructing a SynchronizationMessage
  attr :flags

  # Initializes and sets the state of required update flags.
  def load_flags
    @flags ||= {}
    @flags[:state?] = true
    @flags[:region?] = true
    @flags[:teleport?] = true
  end

  # Resets the update flags for the Mob.
  def reset_flags
    @flags[:chat?] = false
    @flags[:graphic?] = false
    @flags[:animation?] = false
    #@flags[:state?] = false
    @flags[:region?] = false
    @flags[:forced_chat?] = false
    @flags[:teleport?] = false
    @flags[:moved?] = false
  end

  # Toggles the Mob's corresponding value for the passed update type within <@flags>.
  # For example, if we want to schedule a graphic update, we would pass the type :graphic as well as the actual graphic object:
  #
  #  Mob#update(:graphic, gfx: RuneRb::Game::Entity::Graphic)
  #
  # This will toggle the value of the Mob#flags[:graphic?] key to true which will cause a graphic update flag mask and the Graphic object's data to be added to the context's state block in the next ContextSynchronizationMessage.
  #
  # @param type [Symbol] the type of update to schedule
  # @param assets [Hash] the assets for the update
  def update(type, assets = {})
    case type
    when :teleport
      @profile.location.set(assets[:to])
      @position[:current] = @profile.location.to_position
      @movement[:type] = :TELEPORT
      @flags[:teleport?] = true
      @flags[:region?] = true
      @flags[:state?] = true
    when :level_up
      if @profile.stats.level_up?
        level_info = @profile.stats.level_up
        if level_info[:level] == 99
          @session.write_text("Congratulations, you've reached the highest possible #{level_info[:skill].to_s.capitalize} level of 99!")
        else
          @session.write_text("Congratulations, your #{level_info[:skill].to_s.capitalize} level is now #{level_info[:level]}!")
        end
      end
      update(:stats)
      @flags[:state?] = true
    when :equipment
      @equipment.each { |slot_label, stack| @session.write_message(:UpdateSlottedItemMessage, slot: @equipment.keys.index(slot_label), slot_data: stack) }
      @flags[:state?] = true
    when :inventory then @session.write_message(:UpdateItemsMessage, data: @inventory[:container].data, size: 28)
    when :sidebars then RuneRb::Network::SIDEBAR_INTERFACES.each { |key, value| @session.write_message(:DisplaySidebarMessage, menu_id: key, form: value) }
    when :stats
      @session.write_message(:StatUpdateMessage, skill_id: 0, level: @stats[:attack_level], experience: @stats[:attack_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 1, level: @stats[:defence_level], experience: @stats[:defence_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 2, level: @stats[:strength_level], experience: @stats[:strength_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 3, level: @stats[:hit_points_level], experience: @stats[:hit_points_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 4, level: @stats[:range_level], experience: @stats[:range_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 5, level: @stats[:prayer_level], experience: @stats[:prayer_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 6, level: @stats[:magic_level], experience: @stats[:magic_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 7, level: @stats[:cooking_level], experience: @stats[:cooking_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 8, level: @stats[:woodcutting_level], experience: @stats[:woodcutting_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 9, level: @stats[:fletching_level], experience: @stats[:fletching_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 10, level: @stats[:fishing_level], experience: @stats[:fishing_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 11, level: @stats[:firemaking_level], experience: @stats[:firemaking_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 12, level: @stats[:crafting_level], experience: @stats[:crafting_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 13, level: @stats[:smithing_level], experience: @stats[:smithing_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 14, level: @stats[:mining_level], experience: @stats[:mining_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 15, level: @stats[:herblore_level], experience: @stats[:herblore_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 16, level: @stats[:agility_level], experience: @stats[:agility_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 17, level: @stats[:thieving_level], experience: @stats[:thieving_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 18, level: @stats[:slayer_level], experience: @stats[:slayer_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 19, level: @stats[:farming_level], experience: @stats[:farming_exp])
      @session.write_message(:StatUpdateMessage, skill_id: 20, level: @stats[:runecrafting_level], experience: @stats[:runecrafting_exp])
      @flags[:state?] = true
    when :morph
      @profile.appearance.to_mob(assets[:mob_id])
      @flags[:state?] = true
    when :overhead
      @profile.appearance.to_head(assets[:head_icon] <= 7 && assets[:head_icon] >= -1 ? assets[:head_icon] : 0)
      @flags[:state?] = true
    when :region
      @regional = @position[:current].regional
      @flags[:region?] = true
    when :state
      @flags[:state?] = true
    when :graphic
      @graphic = assets[:graphic]
      @flags[:graphic?] = true
      @flags[:state?] = true
    when :animation
      @animation = assets[:animation]
      @flags[:animation?] = true
      @flags[:state?] = true
    when :message, :chat
      @message = assets[:message]
      @flags[:chat?] = true
      @flags[:state?] = true
    else err "Unrecognized update type! #{type}"
    end
  end
end