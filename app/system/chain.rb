module RuneRb::System
  ##
  # A Chain object is represents a collection of linked Routines that will execute sequentially.
  # When Chain#link(routine) is called, a Chain object is returned that will control the execution of the linked routine collection.
  class Chain
    include RuneRb::System::Log
    using RuneRb::System::Patches::SetRefinements

    # @return [Hash] a collection of indexed routines that are to be executed in sequential order according to their hash keys.
    attr :links

    # Called when a new Chain is created
    def initialize
      @links = {}
    end

    # Adds a routine to the chain.
    # @param routine [Routine] the routine to add to the Chain.
    def <<(routine)
      raise 'Invalid Routine!' unless routine.is_a?(Routine)

      idx = @links.empty? ? 0 : @links.keys.last + 1
      @links[idx] = routine
    end

    # Executes all links within the Chain
    # @param consume [Boolean] should links be consumed as they are executed? Default: true
    def execute(consume: true)
      return if @links.empty?

      @process = Fiber.new do
        @links.sort_by { |index, _link| index }
              .each do |index, link|
          @current_idx = index
          next_link = @links[index + 1]
          link.start(next_link&.process)
          @links.delete(index) if consume
        end
      end.resume
    rescue StandardError => e
      err 'An error occurred while executing the chain!', "Execution stopped at #{@current_idx || 0}", e
      puts e.backtrace
    end

    # The length of the Chain's links.
    # @return [Integer] the length of the Chain's links
    def length
      @links.length
    end

    class << self
      # Links two or more Routines together via Chain object.
      # @param routines [Array] an array of Routines to link together
      def link(*routines)
        ch = Chain.new
        routines.each { |routine| ch << routine }
        ch
      end
    end
  end
end
