require 'oauth'
require 'json'
require 'forwardable'

module JIRA
  class OauthClient < RequestClient

    DEFAULT_OPTIONS = {
      :signature_method   => 'RSA-SHA1',
      :request_token_path => "/plugins/servlet/oauth/request-token",
      :authorize_path     => "/plugins/servlet/oauth/authorize",
      :access_token_path  => "/plugins/servlet/oauth/access-token",
      :private_key_file   => "rsakey.pem",
      :consumer_key       => nil,
      :consumer_secret    => nil
    }

    # This exception is thrown when the client is used before the OAuth access token
    # has been initialized.
    class UninitializedAccessTokenError < StandardError
      def message
        "init_access_token must be called before using the client"
      end
    end

    extend Forwardable

    attr_accessor :consumer
    attr_reader :options

    def_instance_delegators :@consumer, :key, :secret, :get_request_token

    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
      @consumer = init_oauth_consumer(@options)
    end

    def init_oauth_consumer(options)
      @options[:request_token_path] = @options[:context_path] + @options[:request_token_path]
      @options[:authorize_path] = @options[:context_path] + @options[:authorize_path]
      @options[:access_token_path] = @options[:context_path] + @options[:access_token_path]
      OAuth::Consumer.new(@options[:consumer_key],@options[:consumer_secret],@options)
    end

    # Returns the current request token if it is set, else it creates
    # and sets a new token.
    def request_token(options = {}, *arguments, &block)
      @request_token ||= get_request_token(options, *arguments, block)
    end

    # Sets the request token from a given token and secret.
    def set_request_token(token, secret)
      @request_token = OAuth::RequestToken.new(@consumer, token, secret)
    end

    # Initialises and returns a new access token from the params hash
    # returned by the OAuth transaction.
    def init_access_token(params)
      @access_token = request_token.get_access_token(params)
    end

    # Sets the access token from a preexisting token and secret.
    def set_access_token(token, secret)
      @access_token = OAuth::AccessToken.new(@consumer, token, secret)
      @authenticated = true
      @access_token
    end

    # Returns the current access token. Raises an
    # JIRA::Client::UninitializedAccessTokenError exception if it is not set.
    def access_token
      raise UninitializedAccessTokenError.new unless @access_token
      @access_token
    end

    def make_request(http_method, path, body='', headers={})
      # When using oauth_2legged we need to add an empty oauth_token parameter to every request.
      if @options[:auth_type] == :oauth_2legged
        oauth_params_str = "oauth_token="
        uri = URI.parse(path)
        if uri.query.to_s == ""
          uri.query = oauth_params_str
        else
          uri.query = uri.query + "&" + oauth_params_str
        end
        path = uri.to_s
      end

      case http_method
      when :delete, :get, :head
        response = access_token.send http_method, path, headers
      when :post, :put
        response = access_token.send http_method, path, body, headers
      end
      @authenticated = true
      response
    end

    def authenticated?
      @authenticated
    end
  end
end
