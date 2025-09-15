# frozen_string_literal: true

require 'json'
require 'forwardable'

module JIRA
  # This class is the main access point for all JIRA::Resource instances.
  #
  # The client must be initialized with an options hash containing
  # configuration options. The available options are:
  #
  #   :site               => 'http://localhost:2990',
  #   :context_path       => '/jira',
  #   :signature_method   => 'RSA-SHA1',
  #   :request_token_path => "/plugins/servlet/oauth/request-token",
  #   :authorize_path     => "/plugins/servlet/oauth/authorize",
  #   :access_token_path  => "/plugins/servlet/oauth/access-token",
  #   :private_key        => nil,
  #   :private_key_file   => "rsakey.pem",
  #   :rest_base_path     => "/rest/api/2",
  #   :consumer_key       => nil,
  #   :consumer_secret    => nil,
  #   :ssl_verify_mode    => OpenSSL::SSL::VERIFY_PEER,
  #   :ssl_version        => nil,
  #   :use_ssl            => true,
  #   :username           => nil,
  #   :password           => nil,
  #   :auth_type          => :oauth,
  #   :proxy_address      => nil,
  #   :proxy_port         => nil,
  #   :proxy_username     => nil,
  #   :proxy_password     => nil,
  #   :use_cookies        => nil,
  #   :additional_cookies => nil,
  #   :default_headers    => {},
  #   :use_client_cert    => false,
  #   :read_timeout       => nil,
  #   :max_retries        => nil,
  #   :http_debug         => false,
  #   :shared_secret      => nil,
  #   :cert_path          => nil,
  #   :key_path           => nil,
  #   :ssl_client_cert    => nil,
  #   :ssl_client_key     => nil
  #   :ca_file            => nil
  #
  # See the JIRA::Base class methods for all of the available methods on these accessor
  # objects.

  class Client
    extend Forwardable

    # The OAuth::Consumer instance returned by the OauthClient
    #
    # The authenticated client instance returned by the respective client type
    # (Oauth, Basic)
    attr_accessor :consumer, :request_client, :http_debug, :field_map_cache

    # The configuration options for this client instance
    attr_reader :options

    def_delegators :@request_client, :init_access_token, :set_access_token, :set_request_token, :request_token,
                   :access_token, :authenticated?

    DEFINED_OPTIONS = %i[
      site
      context_path
      signature_method
      request_token_path
      authorize_path
      access_token_path
      private_key
      private_key_file
      rest_base_path
      consumer_key
      consumer_secret
      ssl_verify_mode
      ssl_version
      use_ssl
      username
      password
      auth_type
      proxy_address
      proxy_port
      proxy_username
      proxy_password
      use_cookies
      additional_cookies
      default_headers
      use_client_cert
      read_timeout
      max_retries
      http_debug
      issuer
      base_url
      shared_secret
      cert_path
      key_path
      ssl_client_cert
      ssl_client_key
    ].freeze

    DEFAULT_OPTIONS = {
      site: 'http://localhost:2990',
      context_path: '/jira',
      rest_base_path: '/rest/api/2',
      ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER,
      use_ssl: true,
      use_client_cert: false,
      auth_type: :oauth,
      http_debug: false,
      default_headers: {}
    }.freeze

    # Creates a new JIRA::Client instance
    # @param [Hash] options The configuration options for the client
    # @option options [Symbol] :auth_type The authentication type to use, :basic, :oauth, :oauth_2legged, or :cookie.
    # @option options [String] :site The base URL for the JIRA instance
    # @option options [Boolean] :use_ssl Whether to use HTTPS for requests
    # @option options [Integer] :ssl_verify_mode The SSL verification mode OpenSSL::SSL::VERIFY_PEER or OpenSSL::SSL::VERIFY_NONE
    # @option options [Hash] :default_headers Additional headers to send with each request
    # @option options [String] :cert_path The path to the SSL certificate file to verify the server with
    # @option options [String] :use_client_cert Whether to use a client certificate for authentication
    # @option options [String] :ssl_client_cert The client certificate to use
    # @option options [String] :ssl_client_key The client certificate key to use
    # @option options [String] :proxy_address The address of the proxy server to use
    # @option options [Integer] :proxy_port The port of the proxy server to use
    # @option options [String] :proxy_username The username for the proxy server
    # @option options [String] :proxy_password The password for the proxy server
    # @return [JIRA::Client] The client instance
    # @raise [ArgumentError] If an unknown option is given
    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @options = options
      @options[:rest_base_path] = @options[:context_path] + @options[:rest_base_path]

      unknown_options = options.keys.reject { |o| DEFINED_OPTIONS.include?(o) }
      raise ArgumentError, "Unknown option(s) given: #{unknown_options}" unless unknown_options.empty?

      if options[:use_client_cert]
        if @options[:cert_path]
          @options[:ssl_client_cert] =
            OpenSSL::X509::Certificate.new(File.read(@options[:cert_path]))
        end
        @options[:ssl_client_key] = OpenSSL::PKey::RSA.new(File.read(@options[:key_path])) if @options[:key_path]

        unless @options[:ssl_client_cert]
          raise ArgumentError,
                'Options: :cert_path or :ssl_client_cert must be set when :use_client_cert is true'
        end
        unless @options[:ssl_client_key]
          raise ArgumentError,
                'Options: :key_path or :ssl_client_key must be set when :use_client_cert is true'
        end
      end

      case options[:auth_type]
      when :oauth, :oauth_2legged
        @request_client = OauthClient.new(@options)
        @consumer = @request_client.consumer
      when :jwt
        @request_client = JwtClient.new(@options)
      when :basic
        @request_client = HttpClient.new(@options)
      when :cookie
        if @options.key?(:use_cookies) && !@options[:use_cookies]
          raise ArgumentError,
                'Options: :use_cookies must be true for :cookie authorization type'
        end

        @options[:use_cookies] = true
        @request_client = HttpClient.new(@options)
        @request_client.make_cookie_auth_request
        @options.delete(:username)
        @options.delete(:password)
      else
        raise ArgumentError, 'Options: ":auth_type" must be ":oauth",":oauth_2legged", ":cookie" or ":basic"'
      end

      @http_debug = @options[:http_debug]

      @options.freeze
    end

    def Project # :nodoc:
      JIRA::Resource::ProjectFactory.new(self)
    end

    def Issue # :nodoc:
      JIRA::Resource::IssueFactory.new(self)
    end

    def Filter # :nodoc:
      JIRA::Resource::FilterFactory.new(self)
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

    def StatusCategory # :nodoc:
      JIRA::Resource::StatusCategoryFactory.new(self)
    end

    def Resolution # :nodoc:
      JIRA::Resource::ResolutionFactory.new(self)
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

    def Transition # :nodoc:
      JIRA::Resource::TransitionFactory.new(self)
    end

    def Field # :nodoc:
      JIRA::Resource::FieldFactory.new(self)
    end

    def Board
      JIRA::Resource::BoardFactory.new(self)
    end

    def BoardConfiguration
      JIRA::Resource::BoardConfigurationFactory.new(self)
    end

    def RapidView
      JIRA::Resource::RapidViewFactory.new(self)
    end

    def Sprint
      JIRA::Resource::SprintFactory.new(self)
    end

    def ServerInfo
      JIRA::Resource::ServerInfoFactory.new(self)
    end

    def Createmeta
      JIRA::Resource::CreatemetaFactory.new(self)
    end

    def ApplicationLink
      JIRA::Resource::ApplicationLinkFactory.new(self)
    end

    def Watcher
      JIRA::Resource::WatcherFactory.new(self)
    end

    def Webhook
      JIRA::Resource::WebhookFactory.new(self)
    end

    def Issuelink
      JIRA::Resource::IssuelinkFactory.new(self)
    end

    def Issuelinktype
      JIRA::Resource::IssuelinktypeFactory.new(self)
    end

    def IssuePickerSuggestions
      JIRA::Resource::IssuePickerSuggestionsFactory.new(self)
    end

    def Remotelink
      JIRA::Resource::RemotelinkFactory.new(self)
    end

    def Agile
      JIRA::Resource::AgileFactory.new(self)
    end

    # HTTP methods without a body

    # Make an HTTP DELETE request
    # @param [String] path The path to request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def delete(path, headers = {})
      request(:delete, path, nil, merge_default_headers(headers))
    end

    # Make an HTTP GET request
    # @param [String] path The path to request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def get(path, headers = {})
      request(:get, path, nil, merge_default_headers(headers))
    end

    # Make an HTTP HEAD request
    # @param [String] path The path to request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def head(path, headers = {})
      request(:head, path, nil, merge_default_headers(headers))
    end

    # HTTP methods with a body

    # Make an HTTP POST request
    # @param [String] path The path to request
    # @param [String] body The body of the request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    def post(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:post, path, body, merge_default_headers(headers))
    end

    # Make an HTTP POST request with a file upload
    # @param [String] path The path to request
    # @param [String] file The file to upload
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def post_multipart(path, file, headers = {})
      puts "post multipart: #{path} - [#{file}]" if @http_debug
      res = @request_client.request_multipart(path, file, merge_default_headers(headers))
      puts "response: #{res}" if @http_debug
      res
    end

    # Make an HTTP PUT request
    # @param [String] path The path to request
    # @param [String] body The body of the request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def put(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:put, path, body, merge_default_headers(headers))
    end

    # Sends the specified HTTP request to the REST API through the
    # appropriate method (oauth, basic).
    # @param [Symbol] http_method The HTTP method to use
    # @param [String] path The path to request
    # @param [String] body The body of the request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def request(http_method, path, body = '', headers = {})
      puts "#{http_method}: #{path} - [#{body}]" if @http_debug
      res = @request_client.request(http_method, path, body, headers)
      puts "response: #{res}" if @http_debug
      res
    end

    # @private
    # Stops sensitive client information from being displayed in logs
    def inspect
      "#<JIRA::Client:#{object_id}>"
    end

    protected

    def merge_default_headers(headers)
      { 'Accept' => 'application/json' }.merge(@options[:default_headers]).merge(headers)
    end
  end
end
