module RuneRb::Game::World::Synchronization

  # A pulse operation executes the Synchronization#prepare_sync, Synchronization#sync, and Synchronization#post_sync functions every 600 ms.
  def pulse
    EventMachine.defer(@sync[:pipeline][:operation], @sync[:pipeline][:callback], @sync[:pipeline][:callback]) unless @players.empty?
  end

  private

  def init_sync
    @sync = {
      succeeded: [],
      failed: [],
      pipeline: {
        operation: proc do
          @players.each do |ctx|
            next unless ctx.session.stage == :logged_in

            %i[pre_sync sync post_sync].each { |stage| process_sync(stage, ctx) }
          end
        end.freeze,
        callback: proc do
          unless @sync[:failed].empty?
            @sync[:failed].each do |failure|
              err "An error occurred during #{failure[:stage]} stage for context #{failure[:context].profile.username}!", failure[:error].message
              err failure[:error].backtrace&.join("\n"), to_stdout: false, to_file: true
            end
          end

          @sync[:failed].clear
          @sync[:succeeded].clear
        end.freeze
      }
    }
  end

  def process_sync(stage, context)
    context.send(stage)
    @sync[:succeeded] << context.index if stage == :post_sync
  rescue StandardError => e
    @sync[:failed] << { context: context,  stage: stage, error: e }
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
