module RuneRb::Entity::Commands
  class Morph < RuneRb::Entity::Command
    def execute
      @assets[:context].update(:morph, mob_id: @assets[:command][0].to_i)
    end
  end
end