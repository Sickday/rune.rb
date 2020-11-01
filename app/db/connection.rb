module RuneRb::Database
  PROFILES = Sequel.postgres(ENV['PROFILE_DATABASE'],
                             user: ENV['DATABASE_USER'],
                             password: ENV['DATABASE_PASS'],
                             host: ENV['DATABASE_HOST'])
  SYSTEMS = Sequel.postgres(ENV['SYSTEM_DATABASE'],
                            user: ENV['DATABASE_USER'],
                            password: ENV['DATABASE_pass'],
                            host: ENV['DATABASE_HOST'])
  DEFINITIONS = Sequel.postgres(ENV['DEFINITIONS_DATABASE'],
                                user: ENV['DATABASE_USER'],
                                password: ENV['DATABASE_PASS'],
                                host: ENV['DATABASE_HOST'])
end