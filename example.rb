require 'pp'
require './lib/jira-ruby'
require 'JSON'

options = {
  :private_key_file => "rsakey.pem"
}

CONSUMER_KEY = 'test'

client = JiraRuby::Client.new(CONSUMER_KEY, '', options)

request_token = client.request_token
system "open #{request_token.authorize_url}"

puts "Enter the oauth_verifier: "
oauth_verifier = gets.strip

client.init_access_token(:oauth_verifier => oauth_verifier)

response = client.get('/jira/rest/api/2.0.alpha1/issue/SAMPLE-1')

json = JSON.parse(response.body)
puts json.to_s
