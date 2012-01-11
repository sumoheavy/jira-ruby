module JIRA
  module Resource

    class UserFactory < BaseFactory ; end

    class User < Base
      def self.singular_path(client, key, prefix = '/')
        rest_base_path(client, prefix) + '?username=' + key
      end
    end

  end
end
