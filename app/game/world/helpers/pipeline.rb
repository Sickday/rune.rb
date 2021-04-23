module RuneRb::Game::World::Pipeline

  # Begins executing Actions in the <@stack>.
  def start_pipeline
    # Execute pending actions
    unless @stack.empty?
      begin
        log! "#{@stack.size} Actions in stack"

        # Call the <=> function on each item in the collection and arrange them in an descending order.
        @stack.sort!

        # Update each Action#target to point to the next member of <@stack>
        @stack.each do |action|
          break if action.nil? || action == @stack.last

          action.target_to(@stack[@stack.index(action) + 1].start(auto: false))
        end

        # Start the first action.
        @stack.first.start(auto: true)

        @stack.clear
      rescue StandardError => e
        err "An error occurred while processing Jobs! Halted at Job with ID: #{@stack&.first&.id}", @stack&.first&.inspect, e
        err e.backtrace&.join("\n")
      end
    end
  end

  # Adds a job to be performed in the pipeline
  # @param params [Hash] parameters for the posted Action.
  # @param action [Proc] work to be performed during the Action's execution.
  def post(params, &action)
    @stack << RuneRb::Game::World::Action.new(params) { action.call(params[:assets]) }
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