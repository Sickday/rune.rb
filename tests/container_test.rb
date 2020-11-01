require_relative '../app/rune'

test_container = RuneRb::Game::ItemContainer.new(28)
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

test_container.remove(4151,3)

puts test_container.inspect

15.times { test_container.add(RuneRb::Game::ItemStack.new(1049))}
puts test_container.inspect

10.times { test_container.add(RuneRb::Game::ItemStack.new(1046))}
puts test_container.inspect

#20.times { test_container.add(RuneRb::Game::ItemStack.new(1046))}
#puts test_container.inspect

3.times { test_container.add(RuneRb::Game::ItemStack.new(995, 2**31-1))}

puts test_container.inspect

puts "TOTALS:\n"
puts "PPHAT:\t#{test_container.count(1049)}"
puts "COINS:\t#{test_container.count(995)}"
puts "WPHAT:\t#{test_container.count(1046)}"
puts "AWHIP:\t#{test_container.count(4151)}"
