module JIRA
  module Resource

    class ApplicationLinkFactory < JIRA::BaseFactory # :nodoc:
    end

    class ApplicationLink < JIRA::Base

      REST_BASE_PATH = '/rest/applinks/1.0'

      def self.endpoint_name
        'listApplicationlinks'
      end

      def self.collection_path(client, prefix = '/')
        client.options[:context_path] + REST_BASE_PATH + prefix + self.endpoint_name
      end

      def self.all(client, options = {})
        response = client.get(collection_path(client))
        json = parse_json(response.body)
        json = json['list']
        json.map do |attrs|
          self.new(client, {:attrs => attrs}.merge(options))
        end
      end
    end
  end
end
