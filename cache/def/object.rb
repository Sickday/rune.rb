module Cache::Definitions
  class ObjectDefinitions

    attr :definitions

    Definition = Struct.new(:id, :impenetrable, :interactive, :obstructive, :length, :menu_actions, :name, :solid, :width)

    def initialize(definitions)
      @definitions = definitions
    end
  end
end