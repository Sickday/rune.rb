module RuneRb::Database::Player
  # A profile model related to a corresponding row in the profile table.
  class Profile < Sequel::Model(RuneRb::GLOBAL[:DATABASE].connection[:player_profile])
    include RuneRb::Utils::Logging

    one_to_one :appearance, class: RuneRb::Database::Player::Appearance, key: :id
    one_to_one :settings, class: RuneRb::Database::Player::Settings, key: :id
    one_to_one :skills, class: RuneRb::Database::Player::Skills, key: :id
    one_to_one :location, class: RuneRb::Database::Player::Location, key: :id

    # Get the Position for the Location associated with the Profile.
    # @return [RuneRb::Game::Map::Position] the Position object for the Location associated with the Profile.
    def position
      location.to_position
    end

    class << self
      include RuneRb::Utils::Logging

      # Fetches a profile by the passed string
      # @param name [String] the name of the profile to fetch.
      # @return [RuneRb::Database::Player::Profile, NilClass] the fetched profile or nil if no profile could be located.
      def fetch_profile(name)
        RuneRb::Database::Player::Profile.where(username: name).first
      end

      # Registers a new profile with supplied database.
      # @param data [Hash, Struct] profile database to insert.
      # @return [RuneRb::Database::Player::Profile] the created profile.
      def register(data)
        # Create the profile and associations
        RuneRb::GLOBAL[:DATABASE].connection[:player_profile].insert(username: data[:Username],
                                                                  password: data[:Password],
                                                                  friends: Sequel.pg_array([], 'text'),
                                                                  ignores: Sequel.pg_array([], 'text'),
                                                                  inventory: Oj.dump({}),
                                                                  equipment: Oj.dump({}),
                                                                  name_hash: data[:NameHash],
                                                                  id: data[:Signature])
        RuneRb::GLOBAL[:DATABASE].connection[:player_appearance].insert(id: data[:Signature])
        RuneRb::GLOBAL[:DATABASE].connection[:player_settings].insert(id: data[:Signature])
        RuneRb::GLOBAL[:DATABASE].connection[:player_skills].insert(id: data[:Signature])
        RuneRb::GLOBAL[:DATABASE].connection[:player_location].insert(id: data[:Signature])
        # Return the created profile
        RuneRb::Database::Player::Profile[data[:Signature]]
      rescue StandardError => e
        err 'An error occurred during registration!', e.message
        err e.backtrace&.join("\n")
        err "Offending Block: #{data}"
      end
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
