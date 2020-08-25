module Scratch::Types
  ##
  # A collection of operations that execute sequentially
  class OperationChain
    attr :operations
    attr_accessor :assets

    # Called when a new OperationChain is created
    def initialize(self_exec, operation_list, assets, block)
      @assets ||= assets
      @operations = operation_list || (block ? [block] : [])
      start if self_exec
    end

    # Attempts to execute all operations in this chain.
    # TODO: Ensure operations are [actually] executed sequentially... This would not ensure applications are executed sequentially. Perhaps use a Set for op list var
    def start
      spin { @operations.each(&:call) }
    end
  end
end