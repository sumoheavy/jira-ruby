require 'oauth'
require 'json'
require 'forwardable'

module Jira
  class Client

    extend Forwardable

    class UninitializedAccessTokenError < StandardError
      def message
        "init_access_token must be called before using the client"
      end
    end

    attr_accessor :consumer
    attr_reader :options
    delegate [:key, :secret, :get_request_token] => :consumer

    DEFAULT_OPTIONS = {
      :site               => 'http://localhost:2990',
      :signature_method   => 'RSA-SHA1',
      :request_token_path => "/jira/plugins/servlet/oauth/request-token",
      :authorize_path     => "/jira/plugins/servlet/oauth/authorize",
      :access_token_path  => "/jira/plugins/servlet/oauth/access-token",
      :private_key_file   => "rsakey.pem",
      :rest_base_path     => "/jira/rest/api/2.0.alpha1"
    }

    def initialize(consumer_key, consumer_secret, options={})
      options = DEFAULT_OPTIONS.merge(options)

      @options = options
      @options.freeze
      @consumer = OAuth::Consumer.new(consumer_key,consumer_secret,options)
    end

    def Project
      Jira::Resource::ProjectFactory.new(self)
    end

    def request_token
      @request_token ||= get_request_token
    end

    def init_access_token(params)
      @access_token = request_token.get_access_token(params)
    end

    def set_access_token(token, secret)
      @access_token = OAuth::AccessToken.new(@consumer, token, secret)
    end

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
      request(:post, path, body, merge_default_headers(headers))
    end
    def put(path, body = '', headers = {})
      request(:put, path, body, merge_default_headers(headers))
    end

    def request(http_method, path, *arguments)
      access_token.request(http_method, path, *arguments)
    end

    protected

      def merge_default_headers(headers)
        {'Accept' => 'application/json'}.merge(headers)
      end

  end
end
