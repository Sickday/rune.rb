module RuneRb::Entity
  # A Animation that is performed by an Entity
  class Animation
    # The ID for the animation
    attr :id

    # The delay before the animation should occur.
    attr :delay

    # Called when a new Animation is created.
    # @param id [Integer] the ID for the animation
    # @param delay [Integer] the delay before the animation should be played.
    def initialize(id, delay)
      @id = id
      @delay = delay
    end
  end
end