# Copyright (c) 2021, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
