# frozen_string_literal: true

require 'oauth'
require 'json'
require 'net/https'

module JIRA
  # Base class for request clients specific to a particular authentication method.
  class RequestClient
    # Makes the JIRA REST API call.
    #
    # Returns the response if the request was successful (HTTP::2xx) and
    # raises a JIRA::HTTPError if it was not successful, with the response
    # attached.
    #
    # Generally you should not call this method directly, but use derived classes.
    #
    # File uploads are not supported with this method.  Use request_multipart instead.
    #
    # All arguments are forwarded to {#make_request}.
    #
    # @return [Net::HTTPResponse] The response from the server
    # @raise [JIRA::HTTPError] if it was not successful
    def request(*)
      response = make_request(*)
      raise HTTPError, response unless response.is_a?(Net::HTTPSuccess)

      response
    end

    # Makes a multipart request to the JIRA server.
    #
    # This is used for file uploads.
    #
    # Generally you should not call this method directly, but use derived classes.
    #
    # All arguments are forwarded to {#make_multipart_request}.
    #
    # @return [Net::HTTPResponse] The response from the server
    # @raise [JIRA::HTTPError] if it was not successful
    def request_multipart(*)
      response = make_multipart_request(*)
      raise HTTPError, response unless response.is_a?(Net::HTTPSuccess)

      response
    end

    # Abstract method to make a request to the JIRA server.
    # @abstract
    # @param [Array] args Arguments to pass to the request method
    def make_request(*args)
      raise NotImplementedError
    end

    # Abstract method to make a request to the JIRA server with a file upload.
    # @abstract
    # @param [Array] args Arguments to pass to the request method
    def make_multipart_request(*args)
      raise NotImplementedError
    end
  end
end
