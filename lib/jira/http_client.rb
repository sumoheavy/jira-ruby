require 'json'
require 'net/https'
require 'cgi/cookie'
require 'uri'

module JIRA
  class HttpClient < RequestClient

    DEFAULT_OPTIONS = {
      :username           => '',
      :password           => ''
    }

    attr_reader :options

    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
      @cookies = {}
    end

    def make_cookie_auth_request
      body = { :username => @options[:username], :password => @options[:password] }.to_json
      @options.delete(:username)
      @options.delete(:password)
      make_request(:post, @options[:context_path] + '/rest/auth/1/session', body, {'Content-Type' => 'application/json'})
    end

    def make_request(http_method, url, body='', headers={})
      # When a proxy is enabled, Net::HTTP expects that the request path omits the domain name
      path = request_path(url)
      request = Net::HTTP.const_get(http_method.to_s.capitalize).new(path, headers)
      request.body = body unless body.nil?
      add_cookies(request) if options[:use_cookies]
      request.basic_auth(@options[:username], @options[:password]) if @options[:username] && @options[:password]
      response = basic_auth_http_conn.request(request)
      @authenticated = response.is_a? Net::HTTPOK
      store_cookies(response) if options[:use_cookies]
      response
    end

    def basic_auth_http_conn
      http_conn(uri)
    end

    def http_conn(uri)
      http_conn = nil
      if @options[:proxy_address]
        http_conn = Net::HTTP::new(uri.host, uri.port, @options[:proxy_address], @options.fetch(:proxy_port, 80), @options[:proxy_user], @options[:proxy_pass])
      else
        http_conn = Net::HTTP::new(uri.host, uri.port)
      end
      http_conn.use_ssl = @options[:use_ssl]
      if @options[:use_client_cert]
        http_conn.cert = @options[:cert]
        http_conn.key = @options[:key]
      end
      http_conn.verify_mode = @options[:ssl_verify_mode]
      http_conn.read_timeout = @options[:read_timeout]
      http_conn
    end

    def uri
      uri = URI.parse(@options[:site])
    end

    def authenticated?
      @authenticated
    end

    private

    def request_path(url)
      parsed_uri = URI(url)

      return url unless parsed_uri.is_a?(URI::HTTP)

      parsed_uri.request_uri
    end

    def store_cookies(response)
      cookies = response.get_fields('set-cookie')
      if cookies
        cookies.each do |cookie|
          data = CGI::Cookie.parse(cookie)
          data.delete('Path')
          @cookies.merge!(data)
        end
      end
    end

    def add_cookies(request)
      cookie_array = @cookies.values.map { |cookie| "#{cookie.name}=#{cookie.value[0]}" }
      cookie_array +=  Array(@options[:additional_cookies]) if @options.key?(:additional_cookies)
      request.add_field('Cookie', cookie_array.join('; ')) if cookie_array.any?
      request
    end
  end
end
