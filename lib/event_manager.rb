require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clear_phone_numbers(number)
  clean_num = number.gsub(/[()\- .]/, "")

  if clean_num.length > 10 && clean_num[0] == "1"
    return clean_num.sub(clean_num[0],"")
  end

  if clean_num.length < 10 || clean_num.length >= 11
    "Not a valid number."
  end
  clean_num
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def format_date(date)
  formatted_date = Time.strptime(date,"%m/%d/%y %H:%M")
  formatted_date
end



puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

time_array = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  reg_date = row[:regdate]
  time_array.push(format_date(reg_date).hour)

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_numbers = clear_phone_numbers(row[:homephone])
  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id,form_letter)
end

peak_reg_hours = time_array.sum / time_array.length
puts "The average registration time is #{peak_reg_hours.to_i}:00"
