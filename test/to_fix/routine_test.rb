require_relative '../app/pp/rune'


succ = lambda do
  puts "SUCCEEDED!"
end

test_routine = Scratch::Types::Routine.new(false) do
  rand(64).times { puts 'EXECUTING!'; sleep(rand(8)); }
end
test_routine.successful = succ

4.times do
  test_routine.start
end