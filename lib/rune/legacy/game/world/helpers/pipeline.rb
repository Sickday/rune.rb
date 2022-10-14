module RuneRb::Game::World::Pipeline

  # Begins executing Actions in the <World#pipeline>.
  def process_events
    @executors[:event].execute
  end

  # Adds an event to the Event executor.
  # @param params [Hash] parameters for the event.
  # @param context [RuneRb::Game::Entity::Context] the context
  def post_event(params, context)
    @executors[:event].post(RuneRb::Game::World::Event.new(params, self, context))
  end

  # Adds work to be done asynchronous to game world processing.
  # @param params [Hash] parameters for the task
  # @param work [Proc] the work
  def post_task(params, &work)
    @executors[:async].post(params, &work)
  end

  private

  def init_executors
    @executors = { event: FiberSpace::FiberChain.new,
                   async: Concurrent::CachedThreadPool.new(max_length: 4),
                   pulse: Concurrent::TimerTask.new(execution_interval: 0.6) do
                     pulse
                   rescue StandardError => e
                     err COLORS.red.bold("An error occurred during pulse operation!"), e.message
                     err e.backtrace&.join("\n"), to_file: true, to_stdout: false
                   end }.freeze
    @executors[:pulse].execute
  end
end

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