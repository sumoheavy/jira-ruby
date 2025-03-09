# frozen_string_literal: true

require 'json'
require 'net/https'
require 'cgi/cookie'
require 'uri'

module JIRA
  # Client using HTTP Basic Authentication
  # @example Basic authentication
  #   options = {
  #     auth_type:        :basic,
  #     site:             "https://jira.example.com",
  #     use_ssl:          true,
  #     ssl_verify_mode:  OpenSSL::SSL::VERIFY_PEER,
  #     cert_path:        '/usr/local/etc/trusted-certificates.pem',
  #     username:         'jamie',
  #     password:         'password'
  #   }
  #   client = JIRA::Client.new(options)
  # @example Bearer token authentication
  #   options = {
  #     auth_type:        :basic,
  #     site:             "https://jira.example.com",
  #     default_headers:  { 'authorization' => "Bearer #{bearer_token_str}" },
  #     use_ssl:          true,
  #     ssl_verify_mode:  OpenSSL::SSL::VERIFY_PEER
  #     cert_path:        '/usr/local/etc/trusted-certificates.pem',
  #   }
  #   client = JIRA::Client.new(options)
  class HttpClient < RequestClient
    # @private
    DEFAULT_OPTIONS = {
      username: nil,
      password: nil
    }.freeze

    # @!attribute [r] options
    #   @return [Hash] The client options
    attr_reader :options

    # Generally not used directly, but through JIRA::Client.
    # See JIRA::Client for documentation.
    # @param [Hash] options Options as passed from JIRA::Client constructor.
    # @option options [String] :username The username to authenticate with
    # @option options [String] :password The password to authenticate with
    # @option options [Hash] :default_headers Additional headers for requests
    # @option options [String] :proxy_uri Proxy URI
    # @option options [String] :proxy_user Proxy user
    # @option options [String] :proxy_password Proxy Password
    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
      @cookies = {}
    end

    def make_cookie_auth_request
      body = { username: @options[:username].to_s, password: @options[:password].to_s }.to_json
      @options.delete(:username)
      @options.delete(:password)
      make_request(:post, "#{@options[:context_path]}/rest/auth/1/session", body, 'Content-Type' => 'application/json')
    end

    # Makes a request to the JIRA server.
    #
    # Generally you should not call this method directly, but use the helper methods in JIRA::Client.
    #
    # File uploads are not supported with this method.  Use make_multipart_request instead.
    #
    # @param [Symbol] http_method The HTTP method to use
    # @param [String] url The JIRA REST URL to call
    # @param [String] body The request body
    # @param [Hash] headers Additional headers to send with the request
    # @return [Net::HTTPResponse] The response from the server
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def make_request(http_method, url, body = '', headers = {})
      # When a proxy is enabled, Net::HTTP expects that the request path omits the domain name
      path = request_path(url)
      request = Net::HTTP.const_get(http_method.to_s.capitalize).new(path, headers)
      request.body = body unless body.nil?

      execute_request(request)
    end

    # Makes a multipart request to the JIRA server.
    #
    # This is used for file uploads.
    #
    # Generally you should not call this method directly, but use the helper methods in JIRA::Client.
    #
    # @param [String] url The JIRA REST URL to call
    # @param [Hash] body The Net::HTTP::Post::Multipart data to send with the request
    # @param [Hash] headers The headers to send with the request
    # @return [Net::HTTPResponse] The response object
    # @raise [JIRA::HTTPError] If the response is not an HTTP success code
    def make_multipart_request(url, body, headers = {})
      path = request_path(url)
      request = Net::HTTP::Post::Multipart.new(path, body, headers)

      execute_request(request)
    end

    # @private
    def basic_auth_http_conn
      http_conn(uri)
    end

    # @private
    def http_conn(uri)
      http_conn =
        if @options[:proxy_address]
          Net::HTTP.new(uri.host, uri.port, @options[:proxy_address], @options[:proxy_port] || 80,
                        @options[:proxy_username], @options[:proxy_password])
        else
          Net::HTTP.new(uri.host, uri.port)
        end
      http_conn.use_ssl = @options[:use_ssl]
      if @options[:use_client_cert]
        http_conn.cert = @options[:ssl_client_cert]
        http_conn.key = @options[:ssl_client_key]
      end
      http_conn.verify_mode = @options[:ssl_verify_mode]
      http_conn.ssl_version = @options[:ssl_version] if @options[:ssl_version]
      http_conn.read_timeout = @options[:read_timeout]
      http_conn.max_retries = @options[:max_retries] if @options[:max_retries]
      http_conn.ca_file = @options[:ca_file] if @options[:ca_file]
      http_conn
    end

    # The URI of the JIRA REST API call
    # @return [URI] The URI of the JIRA REST API call
    def uri
      URI.parse(@options[:site])
    end

    # Returns true if the client is authenticated.
    # @return [Boolean] True if the client is authenticated
    def authenticated?
      @authenticated
    end

    private

    def execute_request(request)
      add_cookies(request) if options[:use_cookies]
      request.basic_auth(@options[:username], @options[:password]) if @options[:username] && @options[:password]

      response = basic_auth_http_conn.request(request)
      @authenticated = response.is_a? Net::HTTPOK
      store_cookies(response) if options[:use_cookies]

      response
    end

    def request_path(url)
      parsed_uri = URI(url)

      return url unless parsed_uri.is_a?(URI::HTTP)

      parsed_uri.request_uri
    end

    def store_cookies(response)
      cookies = response.get_fields('set-cookie')
      return unless cookies

      cookies.each do |cookie|
        data = CGI::Cookie.parse(cookie)
        data.delete('Path')
        @cookies.merge!(data)
      end
    end

    def add_cookies(request)
      cookie_array = @cookies.values.map { |cookie| "#{cookie.name}=#{cookie.value[0]}" }
      cookie_array += Array(@options[:additional_cookies]) if @options.key?(:additional_cookies)
      request.add_field('Cookie', cookie_array.join('; ')) if cookie_array.any?
      request
    end
  end
end
