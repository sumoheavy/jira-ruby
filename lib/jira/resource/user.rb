module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:
    end

    class User < JIRA::Base

      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end

      def self.all(client)
        project_list = client.Project.all.map(&:key).join(',')
        response = client.get("#{client.options[:rest_base_path]}/user/assignable/multiProjectSearch?projectKeys=#{project_list}")
        users = parse_json(response.body)
        users.map do |user|
          client.User.build(user)
        end
      end

    end

  end
end
