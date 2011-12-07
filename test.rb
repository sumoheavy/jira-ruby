require 'pp'
require 'oauth'
require 'JSON'

options = {
  :site => 'http://localhost:2990',
  :signature_method => 'RSA-SHA1',
  :request_token_path => "/jira/plugins/servlet/oauth/request-token",
  :authorize_path => "/jira/plugins/servlet/oauth/authorize",
  :access_token_path => "/jira/plugins/servlet/oauth/access-token",
  :private_key_file => "myrsakey.pem"
}

CONSUMER_KEY = 'test'
CONSUMER_SECRET = "" #open('myrsacert.pem').read()

puts CONSUMER_SECRET.inspect
consumer = OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET, options)
consumer.http.set_debug_output($stderr)

  request_token = consumer.get_request_token

  puts request_token.authorize_url
  secret = request_token.secret

  other_request=OAuth::RequestToken.new(consumer, gets().strip(), secret)
  access_token = other_request.get_access_token(:oauth_verifier => gets().strip())
  put access_token

access_token = OAuth::AccessToken.new(consumer, 'xHevFFNO2qpcTSADjOmrgoEjcT776ir6', 'kOojfIQZnj5NTqnL61DZLAVIPX4uykA8')

puts access_token.inspect
pp JSON.parse(access_token.get('/jira/rest/applinks/1.0/applicationlink', 'Accept' => 'application/json').body)
