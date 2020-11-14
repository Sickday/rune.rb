module RuneRb::Map
  # A GameObject represents an Object with a Position on the game map.
  class GameObject
    attr :data

    Properties = Struct.new(:id, :type, :x, :y, :face)

    # Called when a new GameObject is initialized.
    def initialize(params = {})
      @data = Properties.new(id: params[:id] || -1, type: params[:type],
                             x: params[:x], y: params[:y], face: params[:face])
    end

    # Shorthand Property retrieval
    # @param property [Symbol] the property to retrieve.
    def [](property)
      @data[property]
    end

    # Shorthand Property assignment
    # @param property [Symbol] the property to assign
    # @param value [Object] the value the property should hold.
    def []=(property, value)
      @data[property] = value
    end

  end
end