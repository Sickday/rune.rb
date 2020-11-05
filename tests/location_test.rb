require_relative '../app/rune'

require 'faker'
require 'minitest/autorun'
require 'minitest/pride'

class LocationTest < Minitest::Test
  using RuneRb::Patches::StringOverrides

  Credentials = Struct.new(:user, :pass)
  def setup
    super
    rand(0xff).times do
      creds = Credentials.new(Faker::Internet.unique.user_name(specifier: Faker::FunnyName.name), Faker::Internet.password)
      RuneRb::Database::Profile.register(Username: creds[:user], Password: creds[:user], NameHash: creds[:user].to_base37)
    end
  end

  def test_location

  end
end








user_list = []

rand(256).times do
  creds = Credentials.new(rand(256...65535),
                          Faker::Internet.unique.user_name(specifier: Faker::FunnyName.name),
                          Faker::Internet.password)

  puts 'Generated Credentials!'
  puts "UN:\t#{creds[:user]}\nPASS:\t#{creds[:pass]}\tUID:\t#{creds[:uid]}"

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