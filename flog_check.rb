# frozen_string_literal: true

require 'open3'

current_directory = Dir.pwd
puts "Current directory: #{current_directory}"

# Define the patterns for files or directories to exclude
excluded_patterns = [
  "#{current_directory}/app/controllers/integrations/ashby/ashby_controller.rb"
]

# Build the find command with exclusions
find_command = "find #{current_directory}/app -name '*.rb'"
excluded_patterns.each do |pattern|
  find_command += " -not -path '#{pattern}'"
end

# Run the find command and capture the output
output, = Open3.capture2("#{find_command} | xargs flog")

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

  if score.to_f > 105.0
    puts "Flog score for #{method} is too high: #{score}"
    tmp = true
  end
end

if tmp
  exit 1
else
  puts 'All method scores are acceptable'
end
