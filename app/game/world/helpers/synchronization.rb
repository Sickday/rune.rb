module RuneRb::Game::World::Synchronization
  SYNC_STAGES = %i[pre_sync sync post_sync].freeze

  # A pulse operation executes the Synchronization#prepare_sync, Synchronization#sync, and Synchronization#post_sync functions every 600 ms.
  def pulse
    return if @entities[:players].empty? && @entities[:mobs].empty?

    EventMachine.defer(@sync[:pipeline][:operation], @sync[:pipeline][:callback], @sync[:pipeline][:callback])
  end

  private


  def init_sync
    @sync = {}
    @sync[:succeeded] = []
    @sync[:failed] = {}
    @sync.tap do |hash|
      hash[:pipeline] = {}
      hash[:pipeline][:operation] = proc do
        @entities[:players].each_value { |ctx| SYNC_STAGES.each { |stage| process_sync(stage, ctx) } }
      end.freeze

      hash[:pipeline][:callback] = proc do
        if hash[:failed].empty?
          log! "Completed pulse for #{hash[:succeeded].length} contexts" unless hash[:succeeded].empty?
        else
          log! "Completed pulse with #{hash[:failed].length} errors!" unless hash[:succeeded].empty?
          hash[:failed]&.each do |idx, result|
            result.each do |stage, error|
              err "An error occurred during #{stage} stage for context #{@entities[:players][idx].profile.username}!"
              err error.message
              err error.backtrace&.join("\n")
            end
          end
        end
        hash[:failed].clear
        hash[:succeeded].clear
      end.freeze
    end
  end

  def process_sync(stage, context)
    context.send(stage)
    @sync[:succeeded] << context.index if stage == :post_sync
  rescue StandardError => e
    @sync[:failed][context.index] = { stage => e }
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
