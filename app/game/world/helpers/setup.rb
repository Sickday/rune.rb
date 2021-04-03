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

module RuneRb::Game::World::Setup
  private

  # Initializes and loads configuration settings for the World.
  def setup
    raw_data = Oj.load(File.read('assets/config/rrb_world.json'))

    @settings = {}.tap do |hash|
      hash[:label] = raw_data['LABEL'] || "WORLD_" + Druuid.gen
      hash[:max_players] = raw_data['MAX_PLAYERS'].to_i
      hash[:max_mobs] = raw_data['MAX_MOBS'].to_i
      hash[:default_mob_x] = raw_data['DEFAULT_MOB_X'].to_i
      hash[:default_mob_y] = raw_data['DEFAULT_MOB_Y'].to_i
      hash[:default_mob_z] = raw_data['DEFAULT_MOB_Z'].to_i
      hash[:private?] = raw_data['PRIVATE'] ? true : false
    end.freeze
    @entities = { players: {}, mobs: {} }
    @responses = {}
    @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
    @pulse = Concurrent::TimerTask.new(execution_interval: 0.600) do
      @entities[:players].each_value do |context|
        break if @entities[:players].values.empty?

        context.pre_pulse
        context.pulse
        context.post_pulse
      end
    end
  rescue StandardError => e
    err "An error occurred while running setup!", e
    err e.backtrace&.join("\n")
  end
end