require 'forwardable'
module JIRA

  class HTTPError < StandardError
    extend Forwardable

    def_instance_delegators :@response, :message, :code
    attr_reader :response

    def initialize(response)
      @response = response
    end

  end

end
