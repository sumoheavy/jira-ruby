# frozen_string_literal: true

require 'atlassian/jwt'

module JIRA
  class JwtClient < HttpClient
    def make_request(http_method, url, body = '', headers = {})
      @http_method = http_method
      jwt_header = build_jwt_header(url)

      super(http_method, url, body, headers.merge(jwt_header))
    end

    def make_multipart_request(url, data, headers = {})
      @http_method = :post
      jwt_header = build_jwt_header(url)

      super(url, data, headers.merge(jwt_header))
    end

    private

    attr_reader :http_method

    def build_jwt_header(url)
      jwt = build_jwt(url)
      
      {'Authorization' => "JWT #{jwt}"}
    end

    def build_jwt(url)
      claim = Atlassian::Jwt.build_claims \
        @options[:issuer],
        url,
        http_method.to_s,
        @options[:site],
        (Time.now - 60).to_i,
        (Time.now + 86_400).to_i

      JWT.encode claim, @options[:shared_secret]
    end
  end
end