module RuneRb::Game::World::Setup

  def self.setup_global_settings(configuration = {})
    begin
        err 'Unable to locate GLOBAL mapping!' unless configuration[:RAW].has_key?('GLOBAL') unless configuration.has_key?(:RAW)

        configuration[:WORLD] ||= {}
        configuration[:WORLD][:TITLE] = configuration[:RAW]['GLOBAL']['WORLD']['BASE_TITLE'] || "WORLD"
        configuration[:WORLD][:DEFAULT_POSITION] = RuneRb::Game::Map::Position.new(configuration[:RAW]['GLOBAL']['WORLD']['DEFAULT_X']&.to_i || 3222,
                                                                           configuration[:RAW]['GLOBAL']['WORLD']['DEFAULT_Y']&.to_i || 3222,
                                                                           configuration[:RAW]['GLOBAL']['WORLD']['DEFAULT_Z']&.to_i || 0)
        configuration[:WORLD][:MAX_PLAYERS] = configuration[:RAW]['GLOBAL']['WORLD']['MAX_PLAYERS']&.to_i || 256
        configuration[:WORLD][:MAX_MOBS] = configuration[:RAW]['GLOBAL']['WORLD']['MAX_MOBS']&.to_i || 1024
    rescue StandardError => e
      err 'An error occurred while loading GLOBAL world settings!', e, e.backtrace.join("\n")
    end
  end

  private

  # Initializes and loads configuration settings for the World.
  def setup(config)
    @settings = config
    @entities = { players: {}, mobs: {} }
    @responses = {}
    @stack ||= []
    @duration = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
    setup_sync_service
  rescue StandardError => e
    err "An error occurred while running setup!", e, e.backtrace&.join("\n")
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