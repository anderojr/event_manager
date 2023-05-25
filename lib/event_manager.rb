# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require_relative 'config'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = API_KEY

  begin
    fetch_legislators(civic_info, zip)
  rescue StandardError
    handle_error
  end
end

def fetch_legislators(civic_info, zip)
  civic_info.representative_info_by_address(
    address: zip,
    levels: 'country',
    roles: %w[legislatorUpperBody legislatorLowerBody]
  ).officials
end

def handle_error
  'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
  phone_number = phone_number.gsub(/[()\-,. ]/, '')

  if phone_number.length == 11 && phone_number[0] == '1'
    phone_number = phone_number[1..10]
  elsif phone_number.length != 10
    phone_number = nil
  end

  puts phone_number
end

def most_common_reg_day(csv_file)
  reg_day_frequency = Hash.new(0)

  CSV.foreach(csv_file) do |row|
    reg_date = row[:regdate]
    parsed_date = DateTime.strptime(reg_date, '%m/%d/%y %H:%M')
    reg_day = parsed_date.strftime('%A')
    reg_day_frequency[reg_day] += 1
  end

  reg_day_frequency.max_by { |_day, count| count }[0] # most common day
end

def most_common_hour(csv_file)
  reg_hour_frequency = Hash.new(0)

  CSV.foreach(csv_file) do |row|
    reg_date = row[:regdate]
    parsed_date = DateTime.strptime(reg_date, '%m/%d/%y %H:%M')
    reg_hour = parsed_date.hour
    reg_hour_frequency[reg_hour] += 1
  end

  reg_hour_frequency.max_by { |_hour, count| count }[0] # most common hour
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
