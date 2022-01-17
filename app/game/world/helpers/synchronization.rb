module RuneRb::Game::World::Synchronization

  # A pulse operation executes the Synchronization#prepare_sync, Synchronization#sync, and Synchronization#post_sync functions every 600 ms.
  def pulse
    return if @entities[:players].empty? && @entities[:mobs].empty?

    prepare_sync
    sync
    complete_sync
  end

  private

  # Prepare each entity for synchronization.
  def prepare_sync
    post(id: :SYNC_PREPARATION, priority: :HIGH, assets: [@entities[:mobs], @entities[:players]]) do |mobs, players|
      # Complete pre-sync work for mobs
      mobs.each_value(&:pre_sync)

      # Complete pre-sync work for players.
      players.each_value(&:pre_sync)
    end
  end

  # Synchronize all entity states.
  def sync
    post(id: :SYNC, priority: :MEDIUM, assets: [@entities[:mobs], @entities[:players]]) do |mobs, players|
      # Complete synchronization for each player
      players.each_value(&:sync)

      # Complete synchronization for each mob
      mobs.each_value(&:sync)
    end
  end

  # Complete all post-synchronization actions for each entity.
  def complete_sync
    post(id: :SYNC_COMPLETE, priority: :LOW, assets: [@entities[:mobs], @entities[:players]]) do |mobs, players|
      # Complete pre-pulse work for mobs
      mobs.each_value(&:post_sync)

      # Complete pre-pulse work for players.
      players.each_value(&:post_sync)
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
