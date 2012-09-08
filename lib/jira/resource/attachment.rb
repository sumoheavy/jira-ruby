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

      def save!(attrs)
        http_method = :upload
        response = client.send(http_method, url, attrs)
        set_attrs(attrs, false)
        set_attrs_from_response(response)
        @expanded = true
        true
      end
    end

  end
end
