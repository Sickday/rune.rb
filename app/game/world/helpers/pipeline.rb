# A Pipeline object allows for the
module RuneRb::Game::World::Pipeline
=begin
  def process
    return if @jobs.empty?

    log! "#{@jobs.size} jobs in pipeline"

    @jobs.sort!
    @jobs.each do |task|
      break if task.nil? || task == @jobs.last

      @jobs[@stack.index(task) + 1].start
      task.target_to(@jobs[@jobs.index(task) + 1].process)
    end

    @jobs.first&.start
    @jobs.first&.process.resume
    clear
  rescue StandardError => e
    err "An error occurred while processing Jobs! Halted at Job with ID: #{@jobs&.first&.id}", @jobs&.first&.inspect, e
    err e.backtrace&.join("\n")
  end

  # Adds a job to be performed in the pipeline
  def post(params = { id: Druuid.gen, assets: [], priority: :LOW }, &job)
    @jobs << RuneRb::Game::World::Task.new(params) { job.call(params[:assets]) }
  end

  # Clears all jobs within the stack
  def clear
    @jobs.clear
  end
=end
end
