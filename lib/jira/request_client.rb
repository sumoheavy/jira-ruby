require 'oauth'
require 'oauth2'
require 'json'
require 'net/https'

module JIRA
  # Generic request handler
  class RequestClient
    # Returns the response if the request was successful (HTTP::2xx) and
    # raises a JIRA::HTTPError if it was not successful, with the response
    # attached.

    def request(*args)
      response = make_request(*args)
      raise(HTTPError, response) unless successful?(response)

      response
    end

    def successful?(response)
      return true if response.is_a?(Net::HTTPSuccess)
      return true if response.is_a?(OAuth2::Response) && good?

      false
    end

    def good?(status)
      (status >= 200 && status <= 299)
    end
  end
end
