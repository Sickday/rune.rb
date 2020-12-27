module RuneRb::System
  # A ordered set of operations. It also features #successful and #unsuccessful optional callback functions.
  class Routine
    using RuneRb::System::Patches::SetRefinements

    include RuneRb::System::Log

    # @return [Set] a collection of block operations that will be executed sequentially within the Routine.
    attr :operations

    # @return [Fiber] the Fiber object executing the Routine#operations.
    attr :process

    # @return [Proc] an operation which will execute when the routine completes it's execution successfully.
    attr_accessor :successful

    # @return [Proc] an operation which will execute when the routine fails to execute it's operations.
    attr_accessor :failed

    # Called when a new Routine object is created.
    # @param auto [Boolean] silly way to auto-start the routine after it's initialization.
    # @param assets [Array, Hash] parameters passed to the block operations
    def initialize(assets = [], auto = false, &block)
      @assets = assets
      @operations = Set.new
      add_operation(-> { block.call(@assets) }) if block_given?
      start if auto
    end

    # Attempts to execute all operations in the Routine in sequential order.
    # @param after [Fiber, RuneRb::System::Routine, NilClass] an optional fiber to transfer execution to after this fiber completes
    def start(after = nil)
      @process = Fiber.new do
        @operations.each_consume(&:call)
        if after.nil?
          Fiber.yield(@successful.resume) if @successful.is_a? Fiber
          Fiber.yield(@successful) if @successful
          Fiber.yield(successful)
        elsif after.is_a?(Fiber)
          after.transfer
        end
      end.resume
    rescue StandardError => e
      err 'An error occurred during routine execution.', e
      puts e.backtrace
      @failed ? @failed.call : failed
    end

    # Pushes a new operation to the operations collection.
    def add_operation(block_param = nil, &block)
      @operations.add(-> { block.call }) if block_given?
      @operations.add(block_param) if block_param
    end

    alias << add_operation

    private

    def successful; end

    def failed; end
  end
end