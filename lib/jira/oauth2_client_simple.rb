require 'oauth2'
require 'json'
require 'forwardable'

module JIRA
  # Supports 3LO from the point where the user has their access token
  class Oauth2ClientSimple < RequestClient
    DEFAULT_OPTIONS = {
      client: nil
    }.freeze

    # This exception is thrown when the client is used before
    # the OAuth access token has been initialized.
    class UninitializedAccessTokenError < StandardError
      def message
        'init_access_token must be called before using the client'
      end
    end

    extend Forwardable

    attr_accessor :consumer
    attr_reader :options

    def_instance_delegators :@consumer, :key, :secret, :get_request_token

    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
      # @consumer = init_oauth_consumer(@options)
    end

    # def init_oauth_consumer(_options)
    #   @options[:request_token_path] = @options[:context_path] + @options[:request_token_path]
    #   @options[:authorize_path] = @options[:context_path] + @options[:authorize_path]
    #   @options[:access_token_path] = @options[:context_path] + @options[:access_token_path]
    #   OAuth::Consumer.new(@options[:consumer_key], @options[:consumer_secret], @options)
    # end

    # Sets the access token from a preexisting token and secret.
    def set_access_token(token)
      @access_token = OAuth2::AccessToken.new(@options[:client], token)
      @authenticated = true
      @access_token
    end

    # Returns the current access token. Raises an
    # JIRA::Client::UninitializedAccessTokenError exception if it is not set.
    def access_token
      raise UninitializedAccessTokenError unless @access_token

      @access_token
    end

    def make_request(http_method, path, body = '', headers = {})
      puts "METHOD: #{http_method}"
      puts "PATH: #{http_method}"
      case http_method
      when :delete, :get, :head
        response = access_token.request(http_method, path, headers)
      when :post, :put
        response = access_token.request(http_method, path, body, headers)
      end
      @authenticated = true
      response
    end

    def authenticated?
      @authenticated
    end
  end
end
