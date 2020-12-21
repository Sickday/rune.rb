require_relative '../app/pp/rune'
using Scratch::Patches::SetOverride

g = Set[1, 2, 3, 4, 5, 'one', 'two', 'three', 'four', 'five']
p g.inspect
g.each_consume { |elem| p elem }
p g.inspect