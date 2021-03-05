# Copyright (c) 2020, Patrick W.
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

module RuneRb::Database
  # A profile model related to a corresponding row in the profile table.
  class PlayerProfile < Sequel::Model(RuneRb::GLOBAL[:PLAYER_PROFILES])
    one_to_one :appearance, class: RuneRb::Database::PlayerAppearance, key: :name
    one_to_one :settings, class: RuneRb::Database::PlayerSettings, key: :name
    one_to_one :stats, class: RuneRb::Database::PlayerStats, key: :name
    one_to_one :status,   class: RuneRb::Database::PlayerStatus,  key: :name
    one_to_one :location, class: RuneRb::Database::GameLocation, key: :name

    # Registers a new profile with supplied database.
    # @param data [Hash, Struct] profile database to insert.
    # @return [RuneRb::Database::PlayerProfile] the created profile.
    def self.register(data)
      # Create the profile and associations
      RuneRb::GLOBAL[:PLAYER_PROFILES].insert(name: data[:Username], password: data[:Password], name_hash: data[:NameHash])
      RuneRb::GLOBAL[:PLAYER_APPEARANCES].insert(name: data[:Username])
      RuneRb::GLOBAL[:PLAYER_SETTINGS].insert(name: data[:Username])
      RuneRb::GLOBAL[:PLAYER_STATS].insert(name: data[:Username])
      RuneRb::GLOBAL[:PLAYER_LOCATIONS].insert(name: data[:Username])
      RuneRb::GLOBAL[:PLAYER_STATUS].insert(name: data[:Username])
      # Return the created profile
      RuneRb::Database::PlayerProfile[data[:Username]]
    end

    # Get the Position for the Location associated with the Profile.
    # @return [RuneRb::Game::Map::Position] the Position object for the Location associated with the Profile.
    def position
      location.to_position
    end

    class << self
      def fetch_profile(credentials)
        RuneRb::Database::PlayerProfile[credentials[:Username]] || RuneRb::Database::PlayerProfile.register(credentials)
      end
    end
  end
end