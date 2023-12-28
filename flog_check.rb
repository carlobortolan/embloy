# frozen_string_literal: true

require 'open3'

output, = Open3.capture2("find -name '**/Embloy-Core-Server/**/*.rb' | xargs flog")

lines = output.lines
if lines.empty?
  puts 'No Ruby files found or flog command failed'
  exit 1
end

total_score = lines.first.split.last.to_f

puts "Flog total score: #{total_score}"

excluded_methods = ['before#all', 'main#none', 'FeedGenerator::initialize_feed']

tmp = false
lines[1..].each do |line|
  score, method = line.split
  next if excluded_methods.include?(method)

  if score.to_f > 100.0
    puts "Flog score for #{method} is too high: #{score}"
    tmp = true
  end
end

if tmp
  exit 1
else
  puts 'All method scores are acceptable'
end
