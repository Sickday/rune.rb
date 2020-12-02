module RuneRb::Database
  # A profile model related to a corresponding row in the profile table.
  class Profile < Sequel::Model(PROFILES[:profile])
    one_to_one :appearance, class: RuneRb::Database::Appearance, key: :name
    one_to_one :settings, class: RuneRb::Database::Settings, key: :name
    one_to_one :stats, class: RuneRb::Database::Stats, key: :name
    one_to_one :location, class: RuneRb::Database::Location, key: :name

    # Registers a new profile with supplied data.
    # @param data [Hash, Struct] profile data to insert.
    # @return [RuneRb::Database::Profile] the created profile.
    def self.register(data)
      # Create the profile and associations
      PROFILES[:profile].insert(name: data[:Username], password: data[:Password], name_hash: data[:NameHash])
      PROFILES[:settings].insert(name: data[:Username])
      PROFILES[:appearance].insert(name: data[:Username])
      PROFILES[:stats].insert(name: data[:Username])
      PROFILES[:location].insert(name: data[:Username])

      # Return the created profile
      RuneRb::Database::Profile[data[:Username]]
    end

    # Get the Position for the Location associated with the Profile.
    # @return [RuneRb::Map::Position] the Position object for the Location associated with the Profile.
    def position
      location.to_position
    end
  end
end