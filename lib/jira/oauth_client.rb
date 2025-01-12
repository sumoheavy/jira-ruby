# frozen_string_literal: true

require 'oauth'
require 'json'
require 'forwardable'

module JIRA
  # Client using OAuth 1.0
  #
  # @!attribute [rw] consumer
  #   @return [OAuth::Consumer] The oauth consumer object
  # @!attribute [r] options
  #   @return [Hash] The oauth connection options
  # @!attribute [r] access_token
  #   @return [OAuth::AccessToken] The oauth access token
  class OauthClient < RequestClient
    # @private
    DEFAULT_OPTIONS = {
      signature_method: 'RSA-SHA1',
      request_token_path: '/plugins/servlet/oauth/request-token',
      authorize_path: '/plugins/servlet/oauth/authorize',
      access_token_path: '/plugins/servlet/oauth/access-token',
      private_key_file: 'rsakey.pem',
      consumer_key: nil,
      consumer_secret: nil
    }.freeze

    # This exception is thrown when the client is used before the OAuth access token
    # has been initialized.
    class UninitializedAccessTokenError < StandardError
      def message
        'init_access_token must be called before using the client'
      end
    end

    extend Forwardable

    attr_accessor :consumer
    attr_reader :options

    def_instance_delegators :@consumer, :key, :secret, :get_request_token

    # Generally not used directly, but through JIRA::Client.
    # @param [Hash] options Options as passed from JIRA::Client constructor.
    # @option options [String] :signature_method The signature method to use (defaults to 'RSA-SHA1')
    # @option options [String] :request_token_path The path to request a token (defaults to '/plugins/servlet/oauth/request-token')
    # @option options [String] :authorize_path The path to authorize a token (defaults to '/plugins/servlet/oauth/authorize')
    # @option options [String] :access_token_path The path to access a token (defaults to '/plugins/servlet/oauth/access-token')
    # @option options [String] :private_key_file The path to the private key file
    # @option options [String] :consumer_key The OAuth 1.0 consumer key
    # @option options [String] :consumer_secret The OAuth 1.0 consumer secret
    # @option options [Hash] :default_headers Additional headers for requests
    # @option options [String] :proxy_uri Proxy URI
    # @option options [String] :proxy_user Proxy user
    # @option options [String] :proxy_password Proxy Password
    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
      @consumer = init_oauth_consumer(@options)
    end

    # @private
    # Initialises the OAuth consumer object.
    # Generally you should not call this method directly, it is called by the constructor.
    # @param [Hash] _options The options hash
    # @return [OAuth::Consumer] The OAuth consumer object
    def init_oauth_consumer(_options)
      @options[:request_token_path] = @options[:context_path] + @options[:request_token_path]
      @options[:authorize_path] = @options[:context_path] + @options[:authorize_path]
      @options[:access_token_path] = @options[:context_path] + @options[:access_token_path]
      # proxy_address does not exist in oauth's gem context but proxy does
      @options[:proxy] = @options[:proxy_address] if @options[:proxy_address]
      OAuth::Consumer.new(@options[:consumer_key], @options[:consumer_secret], @options)
    end

    # Returns the current request token if it is set, else it creates
    # and sets a new token.
    # @param [Hash] options
    def request_token(options = {}, ...)
      @request_token ||= get_request_token(options, ...)
    end

    # Sets the request token from a given token and secret.
    # @param [String] token The request token
    # @param [String] secret The request token secret
    # @return [OAuth::RequestToken] The request token object
    def set_request_token(token, secret)
      @request_token = OAuth::RequestToken.new(@consumer, token, secret)
    end

    # Initialises and returns a new access token from the params hash
    # returned by the OAuth transaction.
    # @param [Hash] params The params hash returned by the OAuth transaction
    # @return [OAuth::AccessToken] The access token object
    def init_access_token(params)
      @access_token = request_token.get_access_token(params)
    end

    # Sets the access token from a preexisting token and secret.
    # @param [String] token The access token
    # @param [String] secret The access token secret
    # @return [OAuth::AccessToken] The access token object
    def set_access_token(token, secret)
      @access_token = OAuth::AccessToken.new(@consumer, token, secret)
      @authenticated = true
      @access_token
    end

    # Returns the current access token. Raises an
    # JIRA::Client::UninitializedAccessTokenError exception if it is not set.
    # @return [OAuth::AccessToken] The access token object
    def access_token
      raise UninitializedAccessTokenError unless @access_token

      @access_token
    end

    # Makes a request to the JIRA server using the oauth gem.
    #
    # Generally you should not call this method directly, but use the helper methods in JIRA::Client.
    #
    # File uploads are not supported with this method.  Use make_multipart_request instead.
    #
    # @param [Symbol] http_method The HTTP method to use
    # @param [String] url The JIRA REST URL to call
    # @param [String] body The body of the request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def make_request(http_method, url, body = '', headers = {})
      # When using oauth_2legged we need to add an empty oauth_token parameter to every request.
      if @options[:auth_type] == :oauth_2legged
        oauth_params_str = 'oauth_token='
        uri = URI.parse(url)
        uri.query = if uri.query.to_s == ''
                      oauth_params_str
                    else
                      "#{uri.query}&#{oauth_params_str}"
                    end
        url = uri.to_s
      end

      case http_method
      when :delete, :get, :head
        response = access_token.send http_method, url, headers
      when :post, :put
        response = access_token.send http_method, url, body, headers
      end
      @authenticated = true
      response
    end

    # Makes a multipart request to the JIRA server using the oauth gem.
    #
    # This is used for file uploads.
    #
    # Generally you should not call this method directly, but use the helper methods in JIRA::Client.
    #
    # @param [String] url The JIRA REST URL to call
    # @param [Hash] data The Net::HTTP::Post::Multipart data to send with the request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def make_multipart_request(url, data, headers = {})
      request = Net::HTTP::Post::Multipart.new url, data, headers

      access_token.sign! request

      response = consumer.http.request(request)
      @authenticated = true
      response
    end

    # Returns true if the client is authenticated.
    # @return [Boolean] True if the client is authenticated
    def authenticated?
      @authenticated
    end
  end
end
