module RuneRb::Game
  # An Animation object structures animation data (ID, Delay) sent to clients.
  class Animation
    # The ID for the animation
    attr :id

    # The delay before this animation should occur.
    attr :delay

    # Called when a new Animation is created.
    def initialize(id, delay)
      @id = id
      @delay = delay
    end
  end
end