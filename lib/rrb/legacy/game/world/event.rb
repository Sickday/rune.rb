module RuneRb::Game::World
  class Event < FiberSpace::FiberContainer
    include RuneRb::Utils::Logging

    # Constructs a new Action object.
    # @param params [Hash] Initial parameters for the Action.
    def initialize(params, world, context)
      @world = world
      @context = context
      super(params) { execute(@context) }
    end

    # Execute the Event.
    def execute(_context)
      raise NotImplementedError, 'Event#execute is abstract!'
    end

    def inspect
      "[id]: #{@id}\t||\t[Priority]: #{@priority}"
    end
  end
end