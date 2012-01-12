module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory ; end

    class User < JIRA::Base
      def self.singular_path(client, key, prefix = '/')
        rest_base_path(client, prefix) + '?username=' + key
      end
    end

  end
end
