require_relative 'cache'

obj = RuneRb::Cache::Definitions::GameObject.new(-1)
obj.load_config
defs = 512.times.inject([]) { |arr, itr| arr << obj.object_def(itr) }

defs.each do |definition|
  next if definition.data[:name].nil?

  puts "Parsed #{definition.data[:name]} with actions: #{definition.data[:actions]}"
end