puts 'Event Manager Initialized!'

lines = File.readlines('events_attendees.csv')
lines.each_with_index do |line, index|
  next if index.zero?

  columns = line.split(',')
  name = columns[2]
  puts name
end