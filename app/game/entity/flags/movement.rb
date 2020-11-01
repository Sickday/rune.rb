module RuneRb::Entity::Flags
  class MovementFlags < RuneRb::Game::UpdateFlags
    def initialize
      super(:region_changed, :moved, :teleported)
    end

    def region_changed
    end

    def moved

    end

    def teleported

    end


    def compile
      @payload = Legacy::JOutStream.new
      @payload.switch_access
      if @flags[:region_changed] || @flags[:teleported]
        @payload.write_bits(1, 1)
            .write_bits(2, 3)
            .write_bit(@flags[:teleported])
            .write_bits(2, playerz)
            .write_bits(7, playerx)
            .write_bits(7, playery)
            .write_bits(1, state_update?)
      else
      end

    end
  end
end
