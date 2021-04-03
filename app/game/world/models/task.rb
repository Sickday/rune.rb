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

module RuneRb::Game::World
  # A Task object encapsulates a Fiber that will execute code, then transfer execution context to a target Fiber.
  class Task
    include RuneRb::System::Log

    # @!attribute [r] id
    # @return [Integer] the ID of the object.
    attr :id

    # @!attribute [r] priority
    # @return [Symbol] the priority of the Job.
    attr :priority

    # @!attribute [r] process
    # @return [Fiber] the Fiber that will execute the job.
    attr :process

    # @!attribute [r] target
    # @return [Fiber] the target Fiber.
    attr :target

    # Constructs a new Task object.
    # @param params [Hash] silly way to auto-start the Job after it's initialization.
    # @param block [Proc] parameters passed to the block operations
    def initialize(params, &block)
      @id = params[:id]
      @assets = params[:assets]
      @priority = params[:priority]
      @work = block
    end

    # Attempts to execute all operations in the Job in sequential order.
    def start(auto: false)
      raise 'No operation to perform!' if @work.nil?

      @process = Fiber.new do
        loop do
          Fiber.yield if @completed

          @work.call
          @target&.transfer
          Fiber.yield
        end
      end
      auto ? @process.resume : @process
    end

    # Marks the job as complete causing the <@process> to end.
    def complete
      @completed = true
    end

    # Update the <@target> Fiber to the passed object.
    # @param fiber [Fiber] the new target Fiber.
    def target_to(fiber)
      @target = fiber
    end

    def inspect
      "[id]: #{@id}\t||\t[Priority]: #{@priority}"
    end

    # Mutual comparison operator. Used to sort the Job by it's priority.
    # @param other [Job] the compared Job
    def <=>(other)
      RuneRb::System::PRIORITIES[@priority] <=> RuneRb::System::PRIORITIES[other.priority]
    end
  end
end
