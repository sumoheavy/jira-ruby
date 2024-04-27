module JIRA
  module Resource
    class ApplicationLinkFactory < JIRA::BaseFactory # :nodoc:
      delegate_to_target_class :manifest
    end

    class ApplicationLink < JIRA::Base
      REST_BASE_PATH = '/rest/applinks/1.0'.freeze

      def self.endpoint_name
        'listApplicationlinks'
      end

      def self.full_url(client)
        client.options[:context_path] + REST_BASE_PATH
      end

      def self.collection_path(client, prefix = '/')
        full_url(client) + prefix + endpoint_name
      end

      def self.all(client, options = {})
        response = client.get(collection_path(client))
        json = parse_json(response.body)
        json = json['list']
        json.map do |attrs|
          new(client, { attrs: attrs }.merge(options))
        end
      end

      def self.manifest(client)
        url = full_url(client) + '/manifest'
        response = client.get(url)
        json = parse_json(response.body)
        JIRA::Base.new(client, attrs: json)
      end
    end
  end
end
