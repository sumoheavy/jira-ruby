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
    end
  end
end
