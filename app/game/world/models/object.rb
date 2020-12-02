module RuneRb::World::Models
  # A GameObject represents an Object with a Position on the game map.
  class GameObject

    # @return [Integer] the ID for the GameObject.
    attr :id

    attr :type

    # @return [RuneRb::Map::Position] the position of the GameObject
    attr :position

    # @return [Integer] the direction the GameObject is facing
    attr :face

    # Called when a new GameObject is initialized.
    def initialize(id, type, position, face)
      @id = id
      @type = type
      @position = position
      @face = face
    end
  end
end