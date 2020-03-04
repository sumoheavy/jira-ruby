require 'atlassian/jwt'

module JIRA
  class JwtClient < HttpClient
    def make_request(http_method, url, body = '', headers = {})
      # When a proxy is enabled, Net::HTTP expects that the request path omits the domain name
      path = request_path(http_method, url)

      request = Net::HTTP.const_get(http_method.to_s.capitalize).new(path, headers)
      request.body = body unless body.nil?

      response = basic_auth_http_conn.request(request)
      @authenticated = response.is_a? Net::HTTPOK
      store_cookies(response) if options[:use_cookies]
      response
    end

    class JwtUriBuilder
      attr_reader :request_url, :http_method, :shared_secret, :site, :issuer

      def initialize(request_url, http_method, shared_secret, site, issuer)
        @request_url = request_url
        @http_method = http_method
        @shared_secret = shared_secret
        @site = site
        @issuer = issuer
      end

      def build
        uri = URI.parse(request_url)
        new_query = URI.decode_www_form(String(uri.query)) << ['jwt', jwt_header]
        uri.query = URI.encode_www_form(new_query)

        return uri.to_s unless uri.is_a?(URI::HTTP)

        uri.request_uri
      end

      private

      def jwt_header
        claim = Atlassian::Jwt.build_claims \
          issuer,
          request_url,
          http_method.to_s,
          site,
          (Time.now - 60).to_i,
          (Time.now + 86_400).to_i

        JWT.encode claim, shared_secret
      end
    end

    private

    def request_path(http_method, url)
      JwtUriBuilder.new(
        url,
        http_method.to_s,
        @options[:shared_secret],
        @options[:site],
        @options[:issuer]
      ).build
    end
  end
end
