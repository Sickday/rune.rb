module RuneRb::World::Commands
  class Morph < RuneRb::World::Command
    def execute
      @assets[:context].update(:morph, mob_id: @assets[:command][0].to_i)
    end
  end
end