require 'oauth'
require 'json'
require 'forwardable'

module JIRA

  # This class is the main access point for all JIRA::Resource instances.
  #
  # The client must be initialized with a consumer_key and consumer secret,
  # and an optional hash of extra configuration options.  The available options
  # are:
  #
  #   :site               => 'http://localhost:2990',
  #   :signature_method   => 'RSA-SHA1',
  #   :request_token_path => "/jira/plugins/servlet/oauth/request-token",
  #   :authorize_path     => "/jira/plugins/servlet/oauth/authorize",
  #   :access_token_path  => "/jira/plugins/servlet/oauth/access-token",
  #   :private_key_file   => "rsakey.pem",
  #   :rest_base_path     => "/jira/rest/api/2"
  #
  #
  # See the JIRA::Base class methods for all of the available methods on these accessor
  # objects.
  #
  class Client

    extend Forwardable

    # This exception is thrown when the client is used before the OAuth access token
    # has been initialized.
    class UninitializedAccessTokenError < StandardError
      def message
        "init_access_token must be called before using the client"
      end
    end

    # The OAuth::Consumer instance used by this client
    attr_accessor :consumer

    # The configuration options for this client instance
    attr_reader :options

    def_instance_delegators :@consumer, :key, :secret, :get_request_token

    DEFAULT_OPTIONS = {
      :site               => 'http://localhost:2990',
      :signature_method   => 'RSA-SHA1',
      :request_token_path => "/jira/plugins/servlet/oauth/request-token",
      :authorize_path     => "/jira/plugins/servlet/oauth/authorize",
      :access_token_path  => "/jira/plugins/servlet/oauth/access-token",
      :private_key_file   => "rsakey.pem",
      :rest_base_path     => "/jira/rest/api/2"
    }

    def initialize(consumer_key, consumer_secret, options={})
      options = DEFAULT_OPTIONS.merge(options)

      @options = options
      @options.freeze
      @consumer = OAuth::Consumer.new(consumer_key,consumer_secret,options)
    end

    def Project # :nodoc:
      JIRA::Resource::ProjectFactory.new(self)
    end

    def Issue # :nodoc:
      JIRA::Resource::IssueFactory.new(self)
    end

    def Component # :nodoc:
      JIRA::Resource::ComponentFactory.new(self)
    end

    def User # :nodoc:
      JIRA::Resource::UserFactory.new(self)
    end

    def Issuetype # :nodoc:
      JIRA::Resource::IssuetypeFactory.new(self)
    end

    def Priority # :nodoc:
      JIRA::Resource::PriorityFactory.new(self)
    end

    def Status # :nodoc:
      JIRA::Resource::StatusFactory.new(self)
    end

    def Comment # :nodoc:
      JIRA::Resource::CommentFactory.new(self)
    end

    def Attachment # :nodoc:
      JIRA::Resource::AttachmentFactory.new(self)
    end

    def Worklog # :nodoc:
      JIRA::Resource::WorklogFactory.new(self)
    end

    def Version # :nodoc:
      JIRA::Resource::VersionFactory.new(self)
    end

    # Returns the current request token if it is set, else it creates
    # and sets a new token.
    def request_token
      @request_token ||= get_request_token
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
    end

    # Returns the current access token. Raises an
    # JIRA::Client::UninitializedAccessTokenError exception if it is not set.
    def access_token
      raise UninitializedAccessTokenError.new unless @access_token
      @access_token
    end

    # HTTP methods without a body
    def delete(path, headers = {})
      request(:delete, path,  merge_default_headers(headers))
    end
    def get(path, headers = {})
      request(:get, path, merge_default_headers(headers))
    end
    def head(path, headers = {})
      request(:head, path, merge_default_headers(headers))
    end

    # HTTP methods with a body
    def post(path, body = '', headers = {})
      headers = {'Content-Type' => 'application/json'}.merge(headers)
      request(:post, path, body, merge_default_headers(headers))
    end
    def put(path, body = '', headers = {})
      headers = {'Content-Type' => 'application/json'}.merge(headers)
      request(:put, path, body, merge_default_headers(headers))
    end

    # Sends the specified HTTP request to the REST API through the
    # OAuth token.
    #
    # Returns the response if the request was successful (HTTP::2xx) and
    # raises a JIRA::HTTPError if it was not successful, with the response
    # attached.
    def request(http_method, path, *arguments)
      response = access_token.request(http_method, path, *arguments)
      raise HTTPError.new(response) unless response.kind_of?(Net::HTTPSuccess)
      response
    end

    protected

      def merge_default_headers(headers)
        {'Accept' => 'application/json'}.merge(headers)
      end

  end
end
