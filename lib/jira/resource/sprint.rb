require 'cgi'

module JIRA
  module Resource

    class SprintFactory < JIRA::BaseFactory # :nodoc:
    end

    class Sprint < JIRA::Base

      def self.all(client, key)
        response = client.get(path_base(client) + '/sprintquery/' + key.to_s)
        parse_json(response.body)
      end

      def self.find(client, key, options = {})
        options[:maxResults] ||= 100
        options[:startAt] ||= 0
        fields = options[:fields].join(',') unless options[:fields].nil?
        response = client.get("/rest/api/latest/search?jql=sprint=#{key}&fields=#{fields}&startAt=#{options[:startAt]}&maxResults=#{options[:maxResults]}")
        parse_json(response.body)
      end

      private

      def self.path_base(client)
        client.options[:context_path] + '/rest/greenhopper/1.0'
      end

      def path_base(client)
        self.class.path_base(client)
      end

    end

  end
end
