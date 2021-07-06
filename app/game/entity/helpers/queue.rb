module RuneRb::Game::Entity::Helpers::Queue

	private

	def setup_queues
		@queue = {
			WEAK: [],
			NORMAL: [],
			STRONG: []
		}
	end

	def process_queue
		# If we have weak actions bu no other types
		if !@queue[:WEAK].empty? && @queue[:NORMAL].empty? && !@queue[:STRONG].empty?
			@queue[:WEAK].each(&:run)
		else
			# Discard weak actions
			@queue[:WEAK].clear

			@queue[:NORMAL].each(&:run) unless @queue[:NORMAL].empty? || @session.status[:auth] == :LOGGED_OUT

			unless @queue[:STRONG].empty? || @session.status[:auth] == :LOGGED_OUT
				@session.write(:clear_interfaces)
				@queue[:STRONG].each(&:run)
			end
		end
	end
end