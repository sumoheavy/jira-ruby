require 'pp'
require './lib/jira'

options = {
  :private_key_file => "rsakey.pem"
}

CONSUMER_KEY = 'test'

client = JIRA::Client.new(CONSUMER_KEY, '', options)

if ARGV.length == 0
  # If not passed any command line arguments, open a browser and prompt the
  # user for the OAuth verifier.
  request_token = client.request_token
  puts "Opening #{request_token.authorize_url}"
  system "open #{request_token.authorize_url}"

  puts "Enter the oauth_verifier: "
  oauth_verifier = gets.strip

  access_token = client.init_access_token(:oauth_verifier => oauth_verifier)
  puts "Access token: #{access_token.token} secret: #{access_token.secret}"
elsif ARGV.length == 2
  # Otherwise assume the arguments are a previous access token and secret.
  access_token = client.set_access_token(ARGV[0], ARGV[1])
else
  # Script must be passed 0 or 2 arguments
  raise "Usage: #{$0} [ token secret ]"
end

# Show all projects
projects = client.Project.all

projects.each do |project|
  puts "Project -> key: #{project.key}, name: #{project.name}"
end
issue = client.Issue.find('SAMPLEPROJECT-1')
pp issue

# # Find a specific project by key
# # ------------------------------
# project = client.Project.find('SAMPLEPROJECT')
# pp project
#
# # Delete an issue
# # ---------------
# issue = client.Issue.find('SAMPLEPROJECT-2')
# if issue.delete
#   puts "Delete of issue SAMPLEPROJECT-2 sucessful"
# else
#   puts "Delete of issue SAMPLEPROJECT-2 failed"
# end
#
# # Create an issue
# # ---------------
# issue = client.Issue.build
# issue.save({"fields"=>{"summary"=>"blarg from in example.rb","project"=>{"id"=>"10001"},"issuetype"=>{"id"=>"3"}}})
# issue.fetch
# pp issue
# 
# Update an issue
# ---------------
# issue = client.Issue.find("10002")
# issue.save({"fields"=>{"summary"=>"EVEN MOOOOOOARRR NINJAAAA!"}})
# pp issue
