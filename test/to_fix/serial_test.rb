require_relative 'game/map/map'

puts "Test Serial:"
dump = Map::Areas::F2P[:LUMBRIDGE].dump
puts "Generated dump #{dump}"


sleep(7)

puts "Test Restore:"

f = Map::Boundary.new(0,0,0,0)
f.restore(dump)
puts "Generated#{f}"
