module Scratch::Types
  ##
  # A collection of operations that execute sequentially
  class OperationChain
    using Scratch::Patches::SetOverride

    attr :operations
    attr_accessor :assets

    # Called when a new OperationChain is created
    def initialize(self_exec = false, assets = [], &block)
      @assets = assets
      @operations = block_given? ? Set[block] : Set.new
      start if self_exec
    end

    # Attempts to execute all operations in this chain in sequential order.
    def start
      @operations.each_consume { |operation| spin { operation&.call(@assets) } }
    end

    # Pushes a new operation to the operations collection.
    def add_operation(blck, &block)
      if block_given?
        @operations.add(block)
      elsif blck
        @operations.add(blck)
      else
        raise 'Nil block passed to OperationChain#add_operation call!'
      end
    end

    alias << add_operation
  end
end