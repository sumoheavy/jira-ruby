require 'json'
require 'net/https'

module JIRA
  class HttpClient < RequestClient

    DEFAULT_OPTIONS = {
      :username           => '',
      :password           => ''
    }

    attr_reader :options

    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def make_request(http_method, path, body='', headers)
      request = Net::HTTP.const_get(http_method.capitalize).new(path, headers)
      request.body = body unless body.nil?
      request.basic_auth(@options[:username], @options[:password])
      response = basic_auth_http_conn.request(request)
      response
    end

    def basic_auth_http_conn
      http_conn(uri)
    end

    def http_conn(uri)
      http_conn = Net::HTTP.new(uri.host, uri.port)
      http_conn.use_ssl = @options[:use_ssl]
      http_conn.verify_mode = @options[:ssl_verify_mode]
      http_conn
    end

    def uri
      uri = URI.parse(@options[:site])
    end
  end
end
