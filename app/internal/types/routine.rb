module RuneRb::Types
  class Routine
    include RuneRb::Types::Loggable

    attr_accessor :callback
    # Called when a new Routine object is created.
    # @param self_exec [Boolean] silly way to auto-start the routine after it's initialization.
    # @param assets [Array, Hash] parameters passed to the block operations
    def initialize(self_exec = false, assets = [], &block)
      @callback = -> { block.call(assets) } if block_given?
      start if self_exec
    end

    # Begins the execution of the routine.
    def start
      Concurrent::Future.execute { execute }
      @callback&.call || successful
    rescue StandardError => e
      err 'An error occurred during routine execution.', e
      unsuccessful
    end

    private

    def execute; end

    def successful; end

    def unsuccessful; end
  end
end