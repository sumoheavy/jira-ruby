require 'pp'
require './lib/jira'

options = {
  :private_key_file => "rsakey.pem"
}

CONSUMER_KEY = 'test'

client = Jira::Client.new(CONSUMER_KEY, '', options)

request_token = client.request_token
puts "Opening #{request_token.authorize_url}"
system "open #{request_token.authorize_url}"

puts "Enter the oauth_verifier: "
oauth_verifier = gets.strip

client.init_access_token(:oauth_verifier => oauth_verifier)

# Show all projects
projects = client.Project.all

projects.each do |project|
  puts "Project -> key: #{project.key}, name: #{project.name}"
end

# # Find a specific project by key
# project = client.Project.find('SAMPLEPROJECT')
# pp project
