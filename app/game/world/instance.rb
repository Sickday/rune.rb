module RuneRb::Game::World
  # A World Instance object models a virtual game world. The Instance object manages mobs, events, and most of all the game logic processing.
  class Instance
    using RuneRb::Utils::Patches::SetRefinements
    using RuneRb::Utils::Patches::IntegerRefinements

    include RuneRb::Utils::Logging
    include Gateway
    include Pipeline
    include Synchronization

    # @return [Hash] a map of entities the Instance has spawned
    attr :entities

    # @return [Integer] the id of the world instance
    attr :id

    # @return [Struct] a map of properties for the World instance.
    attr :properties

    # @return [Boolean, NilClass] is the instance closed?
    attr :closed

    # Called when a new World Instance is created
    def initialize(config)
      parse_config(config)
      @entities = { players: {}, mobs: {} }
      @responses = {}
      @pipeline = []
      @start = { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), stamp: Time.now }
    end

    def inspect
      "#{COLORS.green("[Signature]: #{COLORS.yellow.bold(@properties.signature)}")}\n#{COLORS.green("[Players]: #{COLORS.yellow.bold(@entities[:players].length)}/#{@properties.max_contexts}]")}\n#{COLORS.green("[Mobs]: #{COLORS.yellow.bold(@entities[:mobs].length)}/#{@properties.max_mobs}]")}"
    end

    # Shut down the world instance, releasing it's contexts.
    def shutdown
      # release all contexts
      @entities[:players].each_value { |context| release(context) }
      # RuneRb::World::Instance.dump(self) if graceful
    ensure
      @closed = true
      log! "Total Instance Up-time: #{up_time}"
    end

    # The current up-time for the server.
    def up_time
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@start[:time] || Time.now)).round(3).to_i.to_ftime
    end

    private

    Properties = Struct.new(:signature, :max_contexts, :max_mobs, :login_limit)

    def parse_config(config)
      @properties = Properties.new
      @properties.signature = Druuid.gen
      @properties.max_contexts = config.max_contexts
      @properties.max_mobs = config.max_mobs
      @properties.login_limit = config.login_limit
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