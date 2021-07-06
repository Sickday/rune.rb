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

module RuneRb::Base::Types

  # Handles the launching, processing, and shutdown of RuneRb::Network::Endpoints and RuneRb::Game::World::Instance objects.
  class Controller
    include Singleton
    include RuneRb::Base::Utils::Logging

    def spawn_world(config = RuneRb::GLOBAL[:WORLD])
      @world.shutdown(graceful: true) if @world
      @world = RuneRb::Game::World::Instance.new(config)
      @world
    end

    def spawn_endpoint
      @endpoint.shutdown(graceful: true) if @endpoint
      @endpoint = RuneRb::Network::Endpoint.new(target: @world)
      @endpoint
    end

    def shutdown(graceful: true)
      Thread.new do
        @world.shutdown(graceful: graceful)
        @endpoint.shutdown(graceful: graceful)
      rescue StandardError => e
        err! "An error occurred during shutdown!", e, e.backtrace.join("\n")
      ensure
        @world.close
        @endpoint.close
        @closed = true
      end.join
    end

    def run
      Signal.trap('INT') { shutdown(graceful: false) }
      Signal.trap('TERM') { shutdown(graceful: true) }

      spawn_world
      spawn_endpoint

      spin_loop do
        break if @closed

        begin
          @endpoint.start_pipeline unless @endpoint.closed?
          # @world.start_pipeline unless @world.closed?
        rescue StandardError => e
          err! "An error has reached the Controller!", e, e.backtrace&.join("\n")
        end
      end
    end

    # Logs information about the controller and it's assets.
    def about
      log! RuneRb::GLOBAL[:COLOR].green("[Endpoints]: #{@endpoints.length}")
      log! RuneRb::GLOBAL[:COLOR].green("[Worlds]: #{@worlds[:instances].length}")
      log! RuneRb::GLOBAL[:COLOR].green("[Endpoints]: #{@endpoints.each(&:inspect)}")
      log! RuneRb::GLOBAL[:COLOR].green("[Worlds]: #{@worlds[:instances].each(&:inspect)}")
    end
  end
end