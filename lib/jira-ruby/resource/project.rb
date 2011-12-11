module JiraRuby
  module Resource
    class Project

      attr_reader :client, :attrs

      def initialize(client, attrs)
        @client = client
        @attrs  = attrs
      end

      def self.all(client)
        response = client.get('/jira/rest/api/2.0.alpha1/project')
        json = JSON.parse(response.body)
        p json
        []
      end
    end
  end
end
