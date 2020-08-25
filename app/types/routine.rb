module Scratch::Types
  class Routine < OperationChain
    include Scratch::Utils

    # @param successful - Callback meant to be called if the execution block completes it's execution with no errors.
    # @param unsuccessful - Error-back meant to be called if an error is raised causing the execution block to fail.
    attr_accessor :successful, :unsuccessful

    # Called when a new Routine object is created.
    # @param self_exec [Boolean] silly way to auto-start the routine after it's initialization.
    # @param operation_list [Array, Set] an optional list of operations.
    # @param assets [Array, Hash] parameters passed to the block operations
    def initialize(self_exec = false, operation_list = Set.new, assets = [], &block)
      super(self_exec, operation_list, assets, block_given? ? -> { block.call(@assets) } : nil)
    end

    # Begins the execution of the routine.
    def start
      log 'Executing!'
      super
      @successful&.call
      log 'Execution successful!'
    rescue StandardError => e
      err 'An error occurred during routine execution.', e
      @unsuccessful&.call
    end
  end
end