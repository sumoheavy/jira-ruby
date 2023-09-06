require 'atlassian/jwt'

module JIRA
  class JwtClient < HttpClient
    def make_request(http_method, url, body = '', headers = {})
      @http_method = http_method
      @jwt = build_jwt(url)

      super(http_method, url, body, headers.merge(jwt_header))
    end

    def make_multipart_request(url, data, headers = {})
      @http_method = :post

      super(url, data, headers)
    end

    class JwtBuilder
      attr_reader :request_url, :http_method, :shared_secret, :site, :issuer

      def initialize(request_url, http_method, shared_secret, site, issuer)
        @request_url = request_url
        @http_method = http_method
        @shared_secret = shared_secret
        @site = site
        @issuer = issuer
      end

      def build
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

    attr_reader :http_method, :jwt

    def build_jwt(url)
      JwtBuilder.new(
        url,
        http_method.to_s,
        @options[:shared_secret],
        @options[:site],
        @options[:issuer]
      ).build
    end

    def jwt_header
      {'Authorization' => "JWT #{jwt}"}
    end
  end
end
