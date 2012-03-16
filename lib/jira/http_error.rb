module JIRA

  class HTTPError < StandardError

    delegate :message, :code, :to => :response
    attr_reader :response

    def initialize(response)
      @response = response
    end

  end

end
