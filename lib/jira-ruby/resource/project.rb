module JiraRuby
  module Resource

    class ProjectFactory

      attr_reader :client

      def initialize(client)
        @client = client
      end

      def all
        Project.all(@client)
      end

      def find(key)
        Project.find(@client, key)
      end
    end

    class Project

      attr_reader :client, :attrs

      def initialize(client, attrs)
        @client = client
        @attrs  = attrs
      end

      # The class methods are never called directly, they are always
      # invoked from a ProjectFactory instance.
      def self.all(client)
        response = client.get('/jira/rest/api/2.0.alpha1/project')
        json = JSON.parse(response.body)
        json.map do |attrs|
          JiraRuby::Resource::Project.new(client, attrs)
        end
      end

      def self.find(client, key)
        response = client.get("/jira/rest/api/2.0.alpha1/project/#{key}")
        json = JSON.parse(response.body)
        self.new(client, json)
      end
    end
  end
end
