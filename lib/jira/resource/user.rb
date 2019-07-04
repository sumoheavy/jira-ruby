module JIRA
  module Resource
    class UserFactory < JIRA::BaseFactory # :nodoc:
      def myself
        instance = build
        response = client.get("#{client.options[:rest_base_path]}/myself")
        instance.set_attrs_from_response(response)
        instance
      end
    end

    class User < JIRA::Base

      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end

      def self.search_endpoint
        'user/search'
      end
      # Cannot retrieve more than 1,000 users through the api, please see: https://jira.atlassian.com/browse/JRASERVER-65089
      def self.all(client, max_results: 1000)
        search_url = [client.options[:rest_base_path], search_endpoint].join('/')
        query_string = "username&maxResults=#{max_results}&includeInactive=true"
        response  = client.get([search_url,query_string].join('?'))
        all_users = JSON.parse(response.body)

        all_users.flatten.uniq.map do |user|
          client.User.build(user)
        end
      end
    end
  end
end
