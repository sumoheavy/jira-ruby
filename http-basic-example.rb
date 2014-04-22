require 'rubygems'
require 'pp'
require 'jira'

if ARGV.length == 0
  # If not passed any command line arguments, prompt the
  # user for the username and password.
  puts "Enter the username: "
  username = gets.strip

  puts "Enter the password: "
  password = gets.strip
elsif ARGV.length == 2
  username, password = ARGV[0], ARGV[1]
else
  # Script must be passed 0 or 2 arguments
  raise "Usage: #{$0} [ username password ]"
end

options = {
            :username => username,
            :password => password,
            :site     => 'http://localhost:8080/',
            :context_path => '',
            :auth_type => :basic,
            :use_ssl => false
          }

client = JIRA::Client.new(options)

# Show all projects
projects = client.Project.all

projects.each do |project|
  puts "Project -> key: #{project.key}, name: #{project.name}"
end

# # Find a specific project by key
# # ------------------------------
# project = client.Project.find('SAMPLEPROJECT')
# pp project
# project.issues.each do |issue|
#   puts "#{issue.id} - #{issue.fields['summary']}"
# end
#
# # List all Issues
# # ---------------
# client.Issue.all.each do |issue|
#   puts "#{issue.id} - #{issue.fields['summary']}"
# end
#
# # List issues by JQL query
# # ------------------------
# client.Issue.jql('PROJECT = "SAMPLEPROJECT"', [comments, summary]).each do |issue|
#   puts "#{issue.id} - #{issue.fields['summary']}"
# end
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
# # Update an issue
# # ---------------
# issue = client.Issue.find("10002")
# issue.save({"fields"=>{"summary"=>"EVEN MOOOOOOARRR NINJAAAA!"}})
# pp issue
#
# # Find a user
# # -----------
# user = client.User.find('admin')
# pp user
#
# # Get all issue types
# # -------------------
# issuetypes = client.Issuetype.all
# pp issuetypes
#
# # Get a single issue type
# # -----------------------
# issuetype = client.Issuetype.find('5')
# pp issuetype
#
# #  Get all comments for an issue
# #  -----------------------------
# issue.comments.each do |comment|
#   pp comment
# end
#
# # Build and Save a comment
# # ------------------------
# comment = issue.comments.build
# comment.save!(:body => "New comment from example script")
#
# # Delete a comment from the collection
# # ------------------------------------
# issue.comments.last.delete
#
# # Update an existing comment
# # --------------------------
# issue.comments.first.save({"body" => "an updated comment frome example.rb"})
