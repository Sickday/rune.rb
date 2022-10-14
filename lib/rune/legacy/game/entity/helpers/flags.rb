# Functions to toggle, load and reset update flags for an Entity.
module RuneRb::Game::Entity::Helpers::Flags

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
      @flags[:looks?] = true
    when :equipment
      @equipment.each { |slot_label, stack| @session.write_message(:UpdateSlottedItemMessage, slot: @equipment.keys.index(slot_label), slot_data: stack) }
    when :inventory then @session.write_message(:UpdateItemsMessage, data: @inventory[:container].data, size: 28)
    when :sidebars then RuneRb::Network::SIDEBAR_INTERFACES.each { |key, value| @session.write_message(:DisplaySidebarMessage, menu_id: key, form: value) }
    when :stats
      @session.write_message(:StatUpdateMessage, skill_id: 0, level: @profile.skills.attack_level, experience: @profile.skills.attack_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 1, level: @profile.skills.defence_level, experience: @profile.skills.defence_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 2, level: @profile.skills.strength_level, experience: @profile.skills.strength_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 3, level: @profile.skills.hit_points_level, experience: @profile.skills.hit_points_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 4, level: @profile.skills.range_level, experience: @profile.skills.range_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 5, level: @profile.skills.prayer_level, experience: @profile.skills.prayer_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 6, level: @profile.skills.magic_level, experience: @profile.skills.magic_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 7, level: @profile.skills.cooking_level, experience: @profile.skills.cooking_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 8, level: @profile.skills.woodcutting_level, experience: @profile.skills.woodcutting_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 9, level: @profile.skills.fletching_level, experience: @profile.skills.fletching_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 10, level: @profile.skills.fishing_level, experience: @profile.skills.fishing_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 11, level: @profile.skills.firemaking_level, experience: @profile.skills.firemaking_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 12, level: @profile.skills.crafting_level, experience: @profile.skills.crafting_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 13, level: @profile.skills.smithing_level, experience: @profile.skills.smithing_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 14, level: @profile.skills.mining_level, experience: @profile.skills.mining_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 15, level: @profile.skills.herblore_level, experience: @profile.skills.herblore_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 16, level: @profile.skills.agility_level, experience: @profile.skills.agility_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 17, level: @profile.skills.thieving_level, experience: @profile.skills.thieving_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 18, level: @profile.skills.slayer_level, experience: @profile.skills.slayer_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 19, level: @profile.skills.farming_level, experience: @profile.skills.farming_experience)
      @session.write_message(:StatUpdateMessage, skill_id: 20, level: @profile.skills.runecrafting_level, experience: @profile.skills.runecrafting_experience)
    when :morph
      @profile.appearance.to_mob(assets[:mob_id])
      @flags[:looks?] = true
    when :overhead
      @profile.appearance.to_head(assets[:head_icon] <= 7 && assets[:head_icon] >= -1 ? assets[:head_icon] : 0)
      @flags[:looks?] = true
    when :region
      @regional = @position[:current].regional
      @flags[:region?] = true
    when :looks
      @flags[:looks?] = true
    when :graphic
      @graphic = assets[:graphic]
      @flags[:graphic?] = true
    when :animation
      @animation = assets[:animation]
      @flags[:animation?] = true
    when :message, :chat
      @message = assets[:message]
      @flags[:chat?] = true
    else err "Unrecognized update type! #{type}"
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