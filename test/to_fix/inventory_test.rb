require_relative '../app/pp/rune'

test_container = RuneRb::Game::Inventory.new
puts test_container.inspect


12.times do
  test_container.add(RuneRb::Game::ItemStack.new(4151))
end

40.times do
  test_container.add(RuneRb::Game::ItemStack.new(995))
end

puts test_container.inspect

test_container.swap(5, 13)
test_container.swap(5, 6)
test_container.swap(12, 8)
test_container.swap(8, 6)
test_container.swap(8, 1)

puts test_container.inspect

test_container.remove(4151,10)

puts test_container.inspect
puts "WEIGHT: #{test_container.weight}"

15.times do
  test_container.add(RuneRb::Game::ItemStack.new(1121))
  puts "WEIGHT: #{test_container.weight}"
end
puts test_container.inspect

10.times do
  test_container.add(RuneRb::Game::ItemStack.new(1123))
  puts "WEIGHT: #{test_container.weight}"
end
puts test_container.inspect

#20.times { test_container.add(RuneRb::Game::ItemStack.new(1046))}
#puts test_container.inspect

3.times { test_container.add(RuneRb::Game::ItemStack.new(995, 2**31-1))}

puts test_container.inspect

puts "WEIGHT: #{test_container.weight}"