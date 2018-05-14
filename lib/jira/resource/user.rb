module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:
    end

    class User < JIRA::Base
      SMALLER_SAMPLE_SIZE = 100

      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end

      # This method is a bit of a hack. There is no way to get a list of all users in Jira, so we concatenate all of the project IDs
      # and use the assignable users endpoint to get a list of users that can be assigned to all projects.
      def self.all(client)
        all_users           = []
        grouped_project_ids = client.Project.all.map(&:key).each_slice(SMALLER_SAMPLE_SIZE).to_a.uniq

        grouped_project_ids.each do |project_ids|
          project_list = project_ids.join(",")
          response     = client.get("#{client.options[:rest_base_path]}/user/assignable/multiProjectSearch?projectKeys=#{project_list}&maxResults=1000")

          all_users << parse_json(response.body)
        end

        all_users.flatten.uniq.map do |user|
          client.User.build(user)
        end
      end

    end

  end
end
