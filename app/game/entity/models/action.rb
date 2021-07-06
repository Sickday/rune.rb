module RuneRb::Game::Entity
	# A Action object encapsulates a Fiber that will execute code, then transfer execution context to a target Fiber.
	class Action
		include RuneRb::Base::Utils::Logging

		# @!attribute [r] label
		# @return [Integer, Symbol] the ID of the object.
		attr :label

		# @!attribute [r] priority
		# @return [Symbol] the priority of the Job.
		attr :priority

		# @!attribute [r] process
		# @return [Routine] the Fiber that will execute the job.
		attr :worker

		# Constructs a new Action object.
		# @param params [Hash] Initial parameters for the Action.
		# @param work [Proc] parameters passed to the block operations
		def initialize(params, &work)
			@label = params[:label] || "UNLABELED_ACTION_#{Druuid.gen}"
			@assets = params[:assets] || []
			@priority = params[:priority] || :WEAK
			@iterations = params[:iterations] || 1
			@worker = RuneRb::Base::Types::Routine.new(auto: params[:start_now], once: !params[:repeat?]) do
				work.call(@assets)
				@iterations -= 1 unless @iterations.zero? || @iterations.negative? || @iterations == -0xff
			end
		end

		def start
			@worker.run
		end

		def inspect
			"[Label:] #{@label}\t||\t[Priority:] #{@priority} || [Iterations:] #{@iterations}"
		end

		# Mutual comparison operator. Used to sort the Job by it's priority.
		# @param other [Job] the compared Job
		def <=>(other)
			RuneRb::Game::Entity::ACTION_PRIORITIES[@priority] <=> RuneRb::Game::Entity::ACTION_PRIORITIES[other.priority]
		end
	end
end