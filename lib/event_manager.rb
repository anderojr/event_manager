# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require_relative 'config'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = API_KEY

  begin
    legislators = fetch_legislators(civic_info, zip)
    format_legislator_names(legislators)
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

def format_legislator_names(legislators)
  legislator_names = legislators.map(&:name)
  legislator_names.join(', ')
end

def handle_error
  'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  puts "#{name} - #{zipcode} - #{legislators}"
end
