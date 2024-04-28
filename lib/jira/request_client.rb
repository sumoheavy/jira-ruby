# frozen_string_literal: true

require 'oauth'
require 'json'
require 'net/https'

module JIRA
  class RequestClient
    # Returns the response if the request was successful (HTTP::2xx) and
    # raises a JIRA::HTTPError if it was not successful, with the response
    # attached.

    def request(*args)
      response = make_request(*args)
      raise HTTPError, response unless response.is_a?(Net::HTTPSuccess)

      response
    end

    def request_multipart(*args)
      response = make_multipart_request(*args)
      raise HTTPError, response unless response.is_a?(Net::HTTPSuccess)

      response
    end

    def make_request(*args)
      raise NotImplementedError
    end

    def make_multipart_request(*args)
      raise NotImplementedError
    end
  end
end