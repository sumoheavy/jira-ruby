require 'forwardable'
module JIRA
  module Resource

    class HTTPError < StandardError
      extend Forwardable

      delegate [:message, :code] => :response
      attr_reader :response

      def initialize(response)
        @response = response
      end

    end
  end
end
