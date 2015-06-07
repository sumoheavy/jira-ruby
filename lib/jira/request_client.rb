require 'oauth'
require 'json'
require 'net/https'
#require 'pry'

module JIRA
  class RequestClient

    # Returns the response if the request was successful (HTTP::2xx) and
    # raises a JIRA::HTTPError if it was not successful, with the response
    # attached.

    def request(*args)
      response = make_request(*args)
      #binding.pry unless response.kind_of?(Net::HTTPSuccess)
      raise HTTPError.new(response) unless response.kind_of?(Net::HTTPSuccess)
      response
    end
  end
end
