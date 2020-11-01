module RuneRb::Entity::Flags
  class StateFlags < RuneRb::Game::UpdateFlags
    def initialize
      super(:face, :animation, :graphic, :chat, :update)
    end

    def enable(*flags)
      super(flags)

      @flags[:face] = true if flags.include? :face
      @flags[:animation] = true if flags.include? :animation
      @flags[:graphic] = true if flags.include? :graphic
      @flags[:chat] = true if flags.include? :chat
      @flags[:update] = true if flags.include? :update
    end

    def disable(*flags)
      super(flags)

      @flags[:face] = false if flags.include? :face
      @flags[:animation] = false if flags.include? :animation
      @flags[:graphic] = false if flags.include? :graphic
      @flags[:chat] = false if flags.include? :chat
      @flags[:update] = false if flags.include? :update
    end
  end
end