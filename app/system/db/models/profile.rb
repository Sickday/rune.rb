module RuneRb::System::Database
  # A profile model related to a corresponding row in the profile table.
  class Profile < Sequel::Model(RuneRb::PLAYER_PROFILES)
    one_to_one :appearance, class: RuneRb::System::Database::Appearance, key: :name
    one_to_one :settings, class: RuneRb::System::Database::Settings, key: :name
    one_to_one :stats, class: RuneRb::System::Database::Stats, key: :name
    one_to_one :location, class: RuneRb::System::Database::Location, key: :name

    # Registers a new profile with supplied data.
    # @param data [Hash, Struct] profile data to insert.
    # @return [RuneRb::System::Database::Profile] the created profile.
    def self.register(data)
      # Create the profile and associations
      RuneRb::PLAYER_PROFILES.insert(name: data[:Username], password: data[:Password], name_hash: data[:NameHash])
      RuneRb::PLAYER_SETTINGS.insert(name: data[:Username])
      RuneRb::PLAYER_APPEARANCES.insert(name: data[:Username])
      RuneRb::PLAYER_STATS.insert(name: data[:Username])
      RuneRb::PLAYER_LOCATIONS.insert(name: data[:Username])
      # Return the created profile
      RuneRb::System::Database::Profile[data[:Username]]
    end

    # Get the Position for the Location associated with the Profile.
    # @return [RuneRb::Game::Map::Position] the Position object for the Location associated with the Profile.
    def position
      location.to_position
    end
  end
end