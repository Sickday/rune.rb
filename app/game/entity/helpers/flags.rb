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
    @flags[:state?] = false
    @flags[:region?] = false
    @flags[:forced_chat?] = false
    @flags[:teleport?] = false
    @flags[:moved?] = false
  end

  # This function will update the Mob's update flags according to the type and assets provided. Under the hood, this function will enable certain update flags and assign values respectively in accordance with the type of update supplied.
  # For example, if we want to schedule a graphic update, we would pass the type :graphic as well as the actual graphic object (Mob#update(:graphic, gfx: RuneRb::Game::Entity::Graphic). Internally, this will enable the Mob#flags[:graphic?] which will cause a graphic update flag mask and the Graphic object's database to be added to the context's state block in the next pulse.
  # TODO: Raise an error to ensure assets are proper for each update type.
  # @param type [Symbol] the type of update to schedule
  # @param assets [Hash] the assets for the update
  def update(type, assets = {})
    case type
    when :teleport
      @profile.location.set(assets[:to])
      @position[:current] = @profile.position
      @movement[:type] = :TELEPORT
      @flags[:teleport?] = true
      @flags[:region?] = true
      @flags[:state?] = true
    when :skill
      if @profile.stats.level_up?
        level_info = @profile.stats.level_up
        if level_info[:level] == 99
          @session.write_text("Congratulations, you've reached the highest possible #{level_info[:skill].to_s.capitalize} level of 99!")
        else
          @session.write_text("Congratulations, your #{level_info[:skill].to_s.capitalize} level is now #{level_info[:level]}!")
        end
      end
      @session.write_message(:skills, @profile.stats)
      @flags[:state?] = true
    when :equipment
      @session.write_message(:equipment, @equipment)
      @flags[:state?] = true
    when :inventory
      @session.write_message(:inventory, @inventory[:container].data)
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