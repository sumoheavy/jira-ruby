require 'json'
require 'forwardable'
require 'ostruct'

module JIRA
  # This class is the main access point for all JIRA::Resource instances.
  #
  # The client must be initialized with an options hash containing
  # configuration options.  The available options are:
  #
  #   :site               => 'http://localhost:2990',
  #   :context_path       => '/jira',
  #   :signature_method   => 'RSA-SHA1',
  #   :request_token_path => "/plugins/servlet/oauth/request-token",
  #   :authorize_path     => "/plugins/servlet/oauth/authorize",
  #   :access_token_path  => "/plugins/servlet/oauth/access-token",
  #   :private_key_file   => "rsakey.pem",
  #   :rest_base_path     => "/rest/api/2",
  #   :consumer_key       => nil,
  #   :consumer_secret    => nil,
  #   :ssl_verify_mode    => OpenSSL::SSL::VERIFY_PEER,
  #   :use_ssl            => true,
  #   :username           => nil,
  #   :password           => nil,
  #   :api_access_token   => nil,
  #   :auth_type          => :oauth,
  #   :proxy_address      => nil,
  #   :proxy_port         => nil,
  #   :additional_cookies => nil,
  #   :default_headers    => {}
  #
  # See the JIRA::Base class methods for all of the available methods on these accessor
  # objects.

  class Client
    extend Forwardable

    # The OAuth::Consumer instance returned by the OauthClient
    #
    # The authenticated client instance returned by the respective client type
    # (Oauth, Basic)
    attr_accessor :consumer, :request_client, :http_debug, :cache

    # The configuration options for this client instance
    attr_reader :options

    def_delegators :@request_client, :init_access_token, :set_access_token, :set_request_token, :request_token, :access_token, :authenticated?

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

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @options = options
      @options[:rest_base_path] = @options[:context_path] + @options[:rest_base_path]

      if options[:use_client_cert]
        raise ArgumentError, 'Options: :cert_path must be set when :use_client_cert is true' unless @options[:cert_path]
        raise ArgumentError, 'Options: :key_path must be set when :use_client_cert is true' unless @options[:key_path]
        @options[:cert] = OpenSSL::X509::Certificate.new(File.read(@options[:cert_path]))
        @options[:key] = OpenSSL::PKey::RSA.new(File.read(@options[:key_path]))
      end

      case options[:auth_type]
      when :oauth, :oauth_2legged
        @request_client = OauthClient.new(@options)
        @consumer = @request_client.consumer
      when :jwt
        @request_client = JwtClient.new(@options)
      when :basic
        raise ArgumentError, 'Options: :you must specify a :api_access_token as opposed to a :password' if @options.key?(:password) && !@options.key?(:api_access_token)
        @request_client = HttpClient.new(@options)
      when :cookie
        raise ArgumentError, 'Options: :use_cookies must be true for :cookie authorization type' if @options.key?(:use_cookies) && !@options[:use_cookies]
        raise ArgumentError, 'Options: when :use_cookies is true you must specify a :password as opposed to an :api_access_token' if @options.key?(:api_access_token) && !@options.key?(:password)
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

      @cache = OpenStruct.new
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

    def RapidView
      JIRA::Resource::RapidViewFactory.new(self)
    end

    def Sprint
      JIRA::Resource::SprintFactory.new(self)
    end

    def SprintReport
      JIRA::Resource::SprintReportFactory.new(self)
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

    def Remotelink
      JIRA::Resource::RemotelinkFactory.new(self)
    end

    def Sprint
      JIRA::Resource::SprintFactory.new(self)
    end

    def Agile
      JIRA::Resource::AgileFactory.new(self)
    end

    # HTTP methods without a body
    def delete(path, headers = {})
      request(:delete, path, nil, merge_default_headers(headers))
    end

    def get(path, headers = {})
      request(:get, path, nil, merge_default_headers(headers))
    end

    def head(path, headers = {})
      request(:head, path, nil, merge_default_headers(headers))
    end

    # HTTP methods with a body
    def post(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:post, path, body, merge_default_headers(headers))
    end

    def put(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:put, path, body, merge_default_headers(headers))
    end

    # Sends the specified HTTP request to the REST API through the
    # appropriate method (oauth, basic).
    def request(http_method, path, body = '', headers = {})
      puts "#{http_method}: #{path} - [#{body}]" if @http_debug
      @request_client.request(http_method, path, body, headers)
    end

    protected

    def merge_default_headers(headers)
      { 'Accept' => 'application/json' }.merge(@options[:default_headers]).merge(headers)
    end
  end
end
