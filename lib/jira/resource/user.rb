module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:
    end

    class User < JIRA::Base

      has_one :displayName, :attribute_key => 'displayName',
                              :class => String

      has_one :emailAddress, :attribute_key => 'emailAddress',
                                :class => String

      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end
    end

  end
end
