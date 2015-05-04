module JIRA
  module Resource

    class VersionFactory < JIRA::BaseFactory # :nodoc:
    end

    class Version < JIRA::Base
      belongs_to :project

      nested_collections true

      def self.endpoint_name
        'versions'
      end

      def self.all(client, options = {})
        project = options[:project]
        unless project
          raise ArgumentError.new("project is required")
        end

        path = "#{project.self}/#{endpoint_name}"
        response = client.get(path)
        json = parse_json(response.body)
        json.map do |version|
          project.versions.build(version)
        end
      end
    end

  end
end
