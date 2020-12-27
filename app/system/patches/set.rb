module RuneRb::System::Patches::SetRefinements
  refine Set do
    ##
    # Consumes elements as they're passed to execution block.
    # @param block [Proc] the execution block
    def each_consume(&block)
      raise 'Nil block passed to Set#each_consume.' unless block_given?

      each { |item| block.call(item); delete(item) }
    end
  end
end