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

      if response.is_a?(Net::HTTPResponse)
        raise HTTPError, response unless response.is_a?(Net::HTTPSuccess)
        return response
      end

      if response.respond_to?(:status)
        raise HTTPError, response unless (200..299).include?(response&.status)
        return response
      end

      raise HTTPError, response
    end

    def request_multipart(*args)
      response = make_multipart_request(*args)

      if response.is_a?(Net::HTTPResponse)
        raise HTTPError, response unless response.is_a?(Net::HTTPSuccess)
        return response
      end

      if response.respond_to?(:status)
        raise HTTPError, response unless (200..299).include?(response&.status)
        return response
      end

      raise HTTPError, response
    end

    def make_request(*args)
      raise NotImplementedError
    end

    def make_multipart_request(*args)
      raise NotImplementedError
    end
  end
end
