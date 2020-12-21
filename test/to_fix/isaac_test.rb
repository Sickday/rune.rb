require_relative '../app/pp/rune'
using RuneRb::Patches::IntegerOverrides

seed = [rand(1 << 32), rand(1 << 32), rand(1 << 32), rand(1 << 32)]

puts "original seed:\t #{seed}"
puts "enc seed:\t #{seed.map { |i| i += 50 }}"

decryptor = RuneRb::Network::ISAAC.new(seed)
encryptor = RuneRb::Network::ISAAC.new(seed.map { |i| i += 50 })

val1 = rand(256)

puts "Val 1: #{val1}"
puts "Enc val 1: #{val1 + encryptor.next_value.unsigned(:byte)}"

puts "Dec val 1: #{val1 - decryptor.next_value.unsigned(:byte)}"