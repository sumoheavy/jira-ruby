require 'oauth2'
require 'json'
require 'forwardable'

module JIRA
  # Supports 3LO from the point where the user has their access token
  class Oauth2ClientSimple < RequestClient
    DEFAULT_OPTIONS = {
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
    end

    # Sets the access token from a preexisting token and secret.
    def set_access_token(token)
      @access_token = token
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
      case http_method
      when :delete, :get, :head
        opts = { headers: headers }
      when :post, :put
        opts = { headers: headers, body: body }
      end
      response = access_token.request(http_method, path, opts)
      @authenticated = true
      response
    end

    def authenticated?
      @authenticated
    end
  end
end
