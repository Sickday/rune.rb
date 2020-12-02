module RuneRb::Entity::Helpers::Flags
  # @return [Hash] a collection of flags to observe when constructing a SynchronizationFrame
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

  # This function will update the Mob's update flags according to the type and assets provided. Under the hood, this function will enable certain update flags and assign values respectively in accordance with the type of update supplied.
  # For example, if we want to schedule a graphic update, we would pass the type :graphic as well as the actual graphic object (Mob#update(:graphic, gfx: RuneRb::Entity::Graphic). Internally, this will enable the Mob#flags[:graphic?] which will cause a graphic update flag mask and the Graphic object's data to be added to the context's state block in the next pulse.
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
      @session.write(:skills, @profile.stats)
      @flags[:state?] = true
    when :equipment
      @session.write(:equipment, @equipment)
      @flags[:state?] = true
    when :inventory
      @session.write(:inventory, @inventory[:container].data)
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