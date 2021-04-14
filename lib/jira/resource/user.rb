module JIRA
  module Resource
    class UserFactory < JIRA::BaseFactory # :nodoc:
    end

    class User < JIRA::Base
      MAX_RESULTS = 1000

      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end

      def self.all(client)
        search_param = client.cloud_instance? ? "query=" : "username=@"
        all_users = []
        start_at = 0

        loop do
          response = client.get("#{collection_path(client)}/search?#{search_param}&maxResults=#{MAX_RESULTS}&startAt=#{start_at}")
          parsed_response = JSON.parse(response.body)

          all_users.concat(parsed_response)

          break if parsed_response.count != MAX_RESULTS

          start_at += MAX_RESULTS
        end

        all_users.map do |user|
          client.User.build(user)
        end
      end
    end
  end
end
