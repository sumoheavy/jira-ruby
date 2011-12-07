Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f } if defined?(Rake)
require "jira_api/version"
require 'oauth'
require 'JSON'

module JiraApi
  class Client
    
    VALID_OPTIONS = [
      :site => 'http://localhost',
      :signature_method => 'RSA-SHA1',
      :request_token_path => "/jira/plugins/servlet/oauth/request-token",
      :authorize_path => "/jira/plugins/servlet/oauth/authorize",
      :access_token_path => "/jira/plugins/servlet/oauth/access-token",
      :consumer_key => '',
      :private_key_file => "rsakey.pem"
    ]

    attr_accessor *VALID_OPTIONS
    attr_accessible :current_access_token

    def initialize(options={:base_url => "http://localhost"})
      VALID_OPTIONS.each do |key|
        instance_variable_set("@#{key}".to_sym, options[key])
      end
    end

    def authenticate
      
      request_token = consumer.get_request_token

      secret = request_token.secret
      # redirect to request_token.authorize_url 

      # User authenticates request token

      # redirect back to application with callback url set in jira
      # retrieve oauth_token and oauth_verifier from callback params
      return_token = OAuth::RequestToken.new(consumer, oauth_token, secret)
      access_token = return_token.get_access_token(:oauth_verifier => oauth_verifier)
      
    end

  end
end
