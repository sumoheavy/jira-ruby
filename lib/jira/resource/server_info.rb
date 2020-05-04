module JIRA
  module Resource
    class ServerInfoFactory < JIRA::BaseFactory # :nodoc:
    end

    class ServerInfo < JIRA::Base
      def self.endpoint_name
        'serverInfo'
      end
      def self.revelio(client, options = {})
      #   response = client.get(collection_path(client))
      #   json = parse_json(response.body)
      #   new(client, { attrs: json }.merge(options))
      # end
        search_url = [client.options[:rest_base_path], endpoint_name].join('/')
        response  = client.get(search_url)
        decorate_server_info_in(response)
      end

      def self.decorate_server_info_in(response)
        server_info = OpenStruct.new(JSON.parse(response.body))
        server_version_string = server_info.version
        server_version_build = Gem::Version.new((server_info.versionNumbers + [server_info.buildNumber]).join('.'))
        server_version_build_date = Time.parse(server_info.buildDate)
        server_info.decorated_version_info = OpenStruct.new(
          label: server_version_string,
          build: server_version_build,
          build_date: server_version_build_date,
          destination: server_info.deploymentType
        )
        server_info
      end
    end
  end
end
