module JIRA
  module Resource

    class UserFactory < BaseFactory ; end

    class User < Base
      def self.singular_path(client, key)
        rest_base_path(client) + '?username=' + key
      end
    end

  end
end
