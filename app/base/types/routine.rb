module RuneRb::Base::Types
  class Routine
    include RuneRb::Base::Utils::Logging

    # @!attribute [r] process
    # @return [Fiber] the fiber executing the Routine's logic.
    attr :process

    # @!attribute [r] target
    # @return [Fiber] the target Fiber.
    attr :target

    # Construct a new Routine.
    # @param params [Array, Hash] - objects passed to the execution block
    # @param auto [Boolean] - should the Routine begin it's execution directly after it's construction?
    # @param once [Boolean] - should the Routine only execute a single time?
    # @param block [Proc] - the execution block for the routine.
    def initialize(*params, auto: true, once: true, &block)
      raise 'No operation to perform!' unless block_given?

      @process = Fiber.new do
        loop do
          break if @completed

          begin
            result = block.call(params)
          rescue StandardError => e
            err 'An error was raised during Routine execution', e, e.backtrace.join("\n")
            stop(e)
          end

          once ? stop(result) : Fiber.yield(result)
        end
      end

      auto ? run : self
    end

    # Executes a single iteration of the Routine's <@process>
    def run
      @process.resume
    end

    # Ensures a Routine cannot execute further
    def stop(result = nil)
      @completed = true
      target ? target.transfer(result) : Fiber.yield(result)
    end

    # Update the <@target> Fiber to the passed object.
    # @param fiber [Fiber] the new target Fiber.
    def target_to(fiber)
      @target = fiber
    end
  end
end