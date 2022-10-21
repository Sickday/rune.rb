module RuneRb
  class Component

    # Constructs a new component
    def initialize
      setup
    end

    # Begin processing the component.
    def process
      raise NoMethodError, 'The Component#process function is abstract and has not been defined!'
    end

    # Setup the component
    def setup
      raise NoMethodError, 'The Component#setup function is abstract and has not been defined!'
    end
  end
end
