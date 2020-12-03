module RuneRb::Database
  # A connection to the profiles database
  PROFILES = Sequel.postgres(ENV['PROFILE_DATABASE'],
                             user: ENV['DATABASE_USER'],
                             password: ENV['DATABASE_PASS'],
                             host: ENV['DATABASE_HOST'])
  # A connection to the system database
  SYSTEMS = Sequel.postgres(ENV['SYSTEM_DATABASE'],
                            user: ENV['DATABASE_USER'],
                            password: ENV['DATABASE_PASS'],
                            host: ENV['DATABASE_HOST'])

  # A connection to the definitions database.
  DEFINITIONS = Sequel.postgres(ENV['DEFINITIONS_DATABASE'],
                                user: ENV['DATABASE_USER'],
                                password: ENV['DATABASE_PASS'],
                                host: ENV['DATABASE_HOST'])
end