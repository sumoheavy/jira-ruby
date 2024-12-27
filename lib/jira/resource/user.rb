# frozen_string_literal: true

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
      MAX_RESULTS = 1000

      def self.singular_path(client, key, prefix = '/')
        "#{collection_path(client, prefix)}?accountId=#{key}"
      end

      # Cannot retrieve more than 1,000 users through the api, please see: https://jira.atlassian.com/browse/JRASERVER-65089
      def self.all(client)
        response  = client.get("/rest/api/2/users/search?username=_&maxResults=#{MAX_RESULTS}")
        all_users = JSON.parse(response.body)

        all_users.flatten.uniq.map do |user|
          client.User.build(user)
        end
      end
    end
  end
end
