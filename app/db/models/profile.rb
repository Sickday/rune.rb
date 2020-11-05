module RuneRb::Database
  # A profile model related to a corresponding row in the profile table.
  class Profile < Sequel::Model(PROFILES[:profile])
    one_to_one :appearance, class: RuneRb::Database::Appearance, key: :name
    one_to_one :equipment, class: RuneRb::Database::Equipment, key: :uid
    one_to_one :settings, class: RuneRb::Database::Settings, key: :name
    one_to_one :stats, class: RuneRb::Database::Stats, key: :name
    one_to_one :location, class: RuneRb::Database::Location, key: :name

    # Registers a new profile with supplied data.
    # @param data [Hash, Struct] profile data to insert.
    def self.register(data, name_hash)
      PROFILES[:profile].insert(name: data[:Username], password: data[:Password], name_hash: name_hash)
      PROFILES[:settings].insert(name: data[:Username])
      PROFILES[:appearance].insert(name: data[:Username])
      PROFILES[:equipment].insert(name: data[:Username])
      PROFILES[:stats].insert(name: data[:Username])
      PROFILES[:location].insert(name: data[:Username])
    end
  end
end