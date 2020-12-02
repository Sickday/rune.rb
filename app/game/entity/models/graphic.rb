module RuneRb::Entity
  # A Graphic that is produced by and displayed to an entity
  class Graphic
    # The ID for the Graphic
    attr :id
    # The delay that should occur before the Graphic is played.
    attr :delay
    # The height at which the Graphic will play.
    attr :height

    # Called when a new Graphic is created.
    # @param id [Integer] the id for the Graphic
    # @param delay [Integer] the delay that should occur before the Graphic is displayed
    # @param height [Integer] the height at which the Graphic will play.
    def initialize(id, delay, height)
      @id = id
      @delay = delay
      @height = height
    end
  end
end