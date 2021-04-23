module RuneRb::Game::World
  # A World Instance object models a virtual game world. The Instance object manages mobs, events, and most of all the game logic processing.
  class Instance
    using RuneRb::System::Patches::SetRefinements
    using RuneRb::System::Patches::IntegerRefinements

    include RuneRb::System::Log
    include Gateway
    include Pipeline
    include Synchronization
    include Setup

    # @return [Hash] a map of entities the Instance has spawned
    attr :entities

    # @return [Integer] the id of the world instance
    attr :id

    # @return [Hash] a map of settings for the World instance.
    attr :settings

    # Called when a new World Instance is created
    def initialize(config)
      setup(config)
      log 'New World Instance initialized!'
    end

    def inspect
      "#{RuneRb::GLOBAL[:COLOR].green("[Title]: #{RuneRb::GLOBAL[:COLOR].yellow.bold(@settings[:LABEL])}")}\n#{RuneRb::GLOBAL[:COLOR].green("[Players]: #{RuneRb::GLOBAL[:COLOR].yellow.bold(@entities[:players].size)}/#{@settings[:MAX_PLAYERS]}]")}\n#{RuneRb::GLOBAL[:COLOR].green("[Mobs]: #{RuneRb::GLOBAL[:COLOR].yellow.bold(@entities[:mobs].size)}/#{@settings[:MAX_MOBS]}]")}"
    end

    # Shut down the world instance, releasing it's contexts.
    def shutdown
      # release all contexts
      @entities[:players].each_value { |context| release(context) }
      @status = :CLOSED
      # RuneRb::World::Instance.dump(self) if graceful
    ensure
      log! "Total Instance Up-time: #{up_time.to_i.to_ftime}"
    end

    # The current up-time for the server.
    def up_time
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time] || Time.now)).round(3)
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