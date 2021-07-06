module RuneRb::Game::World

  # TODO: TEST ME.
  # A Action object encapsulates a Fiber that will execute code, then transfer execution context to a target Fiber.
  class Task
    include RuneRb::Base::Utils::Logging

    # @!attribute [r] id
    # @return [Integer, Symbol] the ID of the object.
    attr :label

    # @!attribute [r] priority
    # @return [Symbol] the priority of the Job.
    attr :priority

    # @!attribute [r] process
    # @return [Routine] the Fiber that will execute the job.
    attr :process

    # @!attribute [r] result
    # @return [Object, NilClass]
    attr :result

    # @!attribute [r] target
    # @return [Fiber] the target fiber to execute after work has completed.
    attr_accessor :target

    # Constructs a new Action object.
    # @param params [Hash] Initial parameters for the Action.
    # @param _work [Proc] parameters passed to the block operations
    def initialize(params, &_work)
      @label = params[:id] || params[:label] || "UNLABELED_TASK_#{Druuid.gen}"
      @assets = params[:assets] || []
      @priority = params[:priority] || :LOW
      @process = Fiber.new do |assets|
        yield(assets)
        (@target && @target.is_a?(Fiber)) ? @target.transfer : Fiber.yield
      end
    end

    def execute
      @process.resume(@assets)
    end

    def inspect
      "[Label:] #{@label}\t||\t[Priority:] #{@priority}"
    end

    # Mutual comparison operator. Used to sort the Job by it's priority.
    # @param other [Job] the compared Job
    def <=>(other)
      RuneRb::Game::World::TASK_PRIORITIES[@priority] <=> RuneRb::Game::World::TASK_PRIORITIES[other.priority]
    end
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