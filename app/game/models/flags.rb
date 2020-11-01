module RuneRb::Game
  class UpdateFlags
    #include Serializable
    attr :flags

    def initialize(*flags)
      flags.each { |flag| @flags[flag] = false }
    end

    # Enables flags by setting them to false.
    # @param flags [Array, Symbol] the flag or flags to enable.
    def enable(*flags)
      raise "Invalid flag enablement! #{flags} are not a valid!" unless @flags.keys.include? flags
    end

    # Disables flags by setting them to false.
    # @param flags [Array, Symbol] the flag or flags to disable.
    def disable(*flags)
      raise "Invalid flag enablement! #{flag} is not a valid flag!" unless @flags.keys.include? flags
    end

    # Resets flags to a default value
    # @param to [Boolean] the value to reset the flag to.
    def reset(to = false)
      @flags.each { |flag, _val| @flags[flag] = to }
    end
  end
end