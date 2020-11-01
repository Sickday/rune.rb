module RuneRb::Database
  # A profile model related to a corresponding row in the profile table.
  class Profile < Sequel::Model(PROFILES[:profile])
    one_to_one :appearance, class: RuneRb::Database::Appearance, key: :uid
    one_to_one :equipment, class: RuneRb::Database::Equipment, key: :uid
    one_to_one :settings, class: RuneRb::Database::Settings, key: :uid
    one_to_one :stats, class: RuneRb::Database::Stats, key: :uid
    one_to_one :location, class: RuneRb::Database::Location, key: :uid

    # Registers a new profile with supplied data.
    # @param data [Hash, Struct] profile data to insert.
    def self.register(data, name_hash)
      PROFILES[:profile].insert(uid: data[:UID], username: data[:Username], password: data[:Password], name_hash: name_hash)
      PROFILES[:settings].insert(uid: data[:UID])
      PROFILES[:appearance].insert(uid: data[:UID])
      PROFILES[:equipment].insert(uid: data[:UID])
      PROFILES[:stats].insert(uid: data[:UID])
      PROFILES[:location].insert(uid: data[:UID])
    end
  end
end