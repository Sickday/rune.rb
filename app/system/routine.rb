module RuneRb::Internal
  # A ordered set of asynchronous execution blocks make up most of the functionality of this object. It also features #successful and #unsuccessful optional callback functions.
  class Routine
    using RuneRb::System::Patches::SetOverrides

    include RuneRb::System::Log

    attr_accessor :callback

    # Called when a new Routine object is created.
    # @param self_exec [Boolean] silly way to auto-start the routine after it's initialization.
    # @param assets [Array, Hash] parameters passed to the block operations
    def initialize(self_exec = false, assets = [], &block)
      @callback = -> { block.call(assets) } if block_given?
      @assets = assets
      @operations = Set.new
      start if self_exec
    end

    # Attempts to execute all operations in the Routine in sequential order.
    def start
      @operations.each_consume do |operation|
        spin { operation&.call(@assets) }
      end
      @callback&.call || successful
    rescue StandardError => e
      err 'An error occurred during routine execution.'
      puts e
      puts e.backtrace
      unsuccessful
    end

    # Pushes a new operation to the operations collection.
    def add_operation(blck = nil, &block)
      if block_given?
        @operations.add(block)
      elsif blck
        @operations.add(blck)
      else
        raise 'Nil block passed to OperationChain#add_operation call!'
      end
    end

    alias << add_operation

    def execute; end

    def successful; end

    def unsuccessful; end
  end
end