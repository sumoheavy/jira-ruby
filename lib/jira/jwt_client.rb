require 'atlassian/jwt'

module JIRA
  class JwtClient < HttpClient
    def make_request(http_method, url, body = '', headers = {})
      # When a proxy is enabled, Net::HTTP expects that the request path omits the domain name
      path = request_path(url) + "?jwt=#{jwt_header(http_method, url)}"

      request = Net::HTTP.const_get(http_method.to_s.capitalize).new(path, headers)
      request.body = body unless body.nil?

      response = basic_auth_http_conn.request(request)
      @authenticated = response.is_a? Net::HTTPOK
      store_cookies(response) if options[:use_cookies]
      response
    end

    private

    def jwt_header(http_method, url)
      claim = Atlassian::Jwt.build_claims \
        @options[:issuer],
        url,
        http_method.to_s,
        @options[:site],
        (Time.now - 60).to_i,
        (Time.now + (86400)).to_i

      JWT.encode claim, @options[:shared_secret]
    end
  end
end
