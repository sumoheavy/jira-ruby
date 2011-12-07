Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f } if defined?(Rake)
require "jira_api/version"
require 'oauth'
require 'JSON'

module JiraApi
  class Client
    
  # VALID_OPTIONS = [
  #   :site,
  #   :signature_method,
  #   :request_token_path,
  #   :authorize_path,
  #   :access_token_path,
  #   :consumer_key,
  #   :consumer_secret,
  #   :private_key_file
  # ]

    attr_accessor :current_access_token, :consumer_key, :consumer_secret, :options

    def initialize(consumer_key, consumer_secret, options={
      :site => 'http://localhost',
      :signature_method => 'RSA-SHA1',
      :request_token_path => "/jira/plugins/servlet/oauth/request-token",
      :authorize_path => "/jira/plugins/servlet/oauth/authorize",
      :access_token_path => "/jira/plugins/servlet/oauth/access-token",
      :private_key_file => "rsakey.pem"
    })
  #   VALID_OPTIONS.each do |key|
  #     instance_variable_set("@#{key}".to_sym, options[key])
  #   end
      instance_variable_set(:@options, options)
      instance_variable_set(:@consumer_key, consumer_key)
      instance_variable_set(:@consumer_secret, consumer_secret)
    end

    def authenticate

      consumer = OAuth::Consumer.new(self.consumer_key,self.consumer_secret,self.options)
      
      request_token = consumer.get_request_token

      secret = request_token.secret
      # redirect to request_token.authorize_url 

      # User authenticates request token

      # redirect back to application with callback url set in jira
      # retrieve oauth_token and oauth_verifier from callback params
      return_token = OAuth::RequestToken.new(consumer, oauth_token, secret)
      access_token = return_token.get_access_token(:oauth_verifier => oauth_verifier)
      instance_variable_set(:@access_token, access_token)
    end

  end
end
