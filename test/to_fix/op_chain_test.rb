require_relative '../app/pp/rune'
malpractice = [->(_assets) { puts 'Darker than the east river,' },
               ->(_assets) { puts 'Larger than the empire state,' },
               ->(_assets) { puts 'Where the beast that guard the barbed wire gate,' },
               ->(_assets) { puts 'Is on the job, not my fate.' }]

oc = Scratch::Types::OperationChain.new
puts oc.inspect
malpractice.each { |op| oc << op }
puts oc.inspect
oc.start
p oc.inspect