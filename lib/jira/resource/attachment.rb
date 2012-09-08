module JIRA
  module Resource

    class AttachmentFactory < JIRA::BaseFactory # :nodoc:
    end

    class Attachment < JIRA::Base
      has_one :author, :class => JIRA::Resource::User
      belongs_to :issue
      nested_collections true

      def self.collection_path(client, prefix = '/')
        client.options[:rest_base_path] + prefix + self.endpoint_name + 's'
      end
    end

  end
end
