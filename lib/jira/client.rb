require 'openssl'
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
  #   :rest_base_path_v3 => "/rest/api/3",
  #   :consumer_key       => nil,
  #   :consumer_secret    => nil,
  #   :ssl_verify_mode    => OpenSSL::SSL::VERIFY_PEER,
  #   :use_ssl            => true,
  #   :username           => nil,
  #   :password           => nil,
  #   :auth_type          => :oauth
  #   :proxy_address      => nil
  #   :proxy_port         => nil
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

    def_delegators :@request_client, :init_access_token, :set_access_token, :set_request_token, :request_token,
                   :access_token

    DEFAULT_OPTIONS = {
      site: 'http://localhost:2990',
      context_path: '/jira',
      rest_base_path: '/rest/api/2',
      rest_base_path_v3: '/rest/api/3',
      ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER,
      use_ssl: true,
      auth_type: :oauth,
      http_debug: false
    }

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @options = options
      @options[:rest_base_path] = @options[:context_path] + @options[:rest_base_path]
      @options[:rest_base_path_v3] = @options[:context_path] + @options[:rest_base_path_v3]
      case options[:auth_type]
      when :oauth
        @request_client = OauthClient.new(@options)
        @consumer = @request_client.consumer
      when :basic
        @request_client = HttpClient.new(@options)
      else
        raise ArgumentError, 'Options: ":auth_type" must be ":oauth" or ":basic"'
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

    def cloud_instance?
      options[:site].include?('atlassian.net') || options[:site].include?('jira.com')
    end

    protected

    def merge_default_headers(headers)
      { 'Accept' => 'application/json' }.merge(headers)
    end
  end
end
