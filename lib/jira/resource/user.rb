module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:
    end

    class User < JIRA::Base
      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end
    end

  end
end
