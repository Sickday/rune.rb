
require 'faker'
require_relative 'db/rb'
require_relative 'repo/models/appearance'
require_relative 'repo/models/equipment'
require_relative 'repo/models/settings'
require_relative 'repo/models/stats'
require_relative 'repo/models/location'
require_relative 'repo/models/profile'


Credentials = Struct.new(:uid, :user, :pass)

user_list = []

rand(256).times do
  creds = Credentials.new(rand(256...65535),
                          Faker::Internet.unique.user_name(specifier: Faker::FunnyName.name),
                          Faker::Internet.password)

  puts "Generated Credentials!"
  puts "UN:\t#{creds[:user]}\nPASS:\t#{creds[:pass]}\tUID:\t#{creds[:uid]}"

  Test::CONNECTION[:profile].insert(uid: creds[:uid], username: creds[:user], password: creds[:pass])
  Test::CONNECTION[:settings].insert(uid: creds[:uid])
  Test::CONNECTION[:appearance].insert(uid: creds[:uid])
  Test::CONNECTION[:equipment].insert(uid: creds[:uid])
  Test::CONNECTION[:stats].insert(uid: creds[:uid])
  Test::CONNECTION[:location].insert(uid: creds[:uid])
  user_list << creds[:uid]
  sleep(1)
end

puts "Grabbing 5 random user's credentials!"

5.times do
  prof = Test::Profile[user_list.sample]
  puts "Got Profile:\t#{prof}"
  puts "UN:\t#{prof[:username]}\nPASS:\t#{prof[:password]}\tUID:\t#{prof[:uid]}"
  puts "STATS:\t#{prof.stats.inspect}"
  puts "ATTACK:\t#{prof.stats[:attack_level]}\nSTRENGTH:\t#{prof.stats[:strength_level]}\nDEFENCE:\t#{prof.stats[:defence_level]}"
  sleep(15)
end