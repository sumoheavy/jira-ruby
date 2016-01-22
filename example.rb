require 'pp'
require './lib/jira-ruby'

CONSUMER_KEY = 'test'
SITE         = 'https://test.jira.com'

options = {
  :private_key_file => "rsakey.pem",
  :context_path     => '',
  :consumer_key     => CONSUMER_KEY,
  :site             => SITE
}

client = JIRA::Client.new(options)

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

# List all available link types
# ------------------------------
pp client.Issuelinktype.all

# List issue's links
# -------------------------
issue = client.Issue.find("10002")
pp issue.issuelinks

# Link two issues (on the same Jira instance)
# --------------------------------------------
link = client.Issuelink.build
link.save(
    {
        :type => {:name => 'Relates'},
        :inwardIssue => {:key => 'AL-1'},
        :outwardIssue => {:key => 'AL-2'}
    }
)

# List issue's remote links
# -------------------------
pp issue.remotelink.all

# Link two remote issues (on the different Jira instance)
# In order to add remote links, you have to add
# Application Links between two Jira instances first.
# More information:
# https://developer.atlassian.com/jiradev/jira-platform/guides/other/guide-jira-remote-issue-links/fields-in-remote-issue-links
# http://stackoverflow.com/questions/29850252/jira-api-issuelink-connect-two-different-instances
# -------------------------------------------------------
client_1 = JIRA::Client.new(options)
client_2 = JIRA::Client.new(options)

# you have to search for your app id here, instead of getting the first
client_2_app_link = client_2.ApplicationLink.manifest
issue_1 = client_1.Issue.find('BB-2')
issue_2 = client_2.Issue.find('AA-1')

remote_link = issue_2.remotelink.build

remote_link.save(
    {
        :globalId => "appId=#{client_2_app_link.id}&issueId=#{issue_1.id}",
        :application => {
            :type => 'com.atlassian.jira',
            :name => client_2_app_link['name']
        },
        :relationship => 'relates to',

        :object => {
            :url => client_1.options[:site] + client_1.options[:context_path] + "/browse/#{issue_1.key}",
            :title => issue_1.key,
        }
    }
)
