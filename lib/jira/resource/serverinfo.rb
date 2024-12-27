# frozen_string_literal: true

module JIRA
  module Resource
    class ServerInfoFactory < JIRA::BaseFactory # :nodoc:
    end

    class ServerInfo < JIRA::Base
      def self.endpoint_name
        'serverInfo'
      end

      def self.all(client, options = {})
        response = client.get(collection_path(client))
        json = parse_json(response.body)
        new(client, { attrs: json }.merge(options))
      end
    end
  end
end
