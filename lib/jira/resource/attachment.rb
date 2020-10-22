require 'net/http/post/multipart'

module JIRA
  module Resource
    class AttachmentFactory < JIRA::BaseFactory # :nodoc:
      delegate_to_target_class :meta
    end

    class Attachment < JIRA::Base
      belongs_to :issue
      has_one :author, class: JIRA::Resource::User

      def self.endpoint_name
        'attachments'
      end

      def self.meta(client)
        response = client.get(client.options[:rest_base_path] + '/attachment/meta')
        parse_json(response.body)
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue
        attachments = issue.attachments
        response = client.get(client.options[:rest_base_path] + '/attachment/')
      end

      def self.find(client, key, options = {})
      end

      def save!(attrs, path = url)
        file = attrs['file'] || attrs[:file] # Keep supporting 'file' parameter as a string for backward compatibility
        # If :filename does not exist or is nil, that is fine as it will force
        # UpdateIO to determine the filename automatically from file.
        # Breaking the filename out allows this to support any IO-based file parameter.
        fname = attrs['filename'] || attrs[:filename]
        mime_type = attrs['mimeType'] || attrs[:mimeType] || 'application/binary'

        headers = { 'X-Atlassian-Token' => 'nocheck' }
        data = { 'file' => UploadIO.new(file, mime_type, fname) }

        response = client.post_multipart(path, data, headers)

        set_attributes(attrs, response)

        @expanded = false
        true
      end

      def download
        # Actually fetch the attachment
        # Note: Jira handles attachment's weird!
        # Typically, they respond with a redirect location that should not have the same authentication
        begin
          client.get(attrs['content'])
        rescue JIRA::HTTPError => ex
          raise ex unless ex.response.code_type.eql?(Net::HTTPFound)
          Net::HTTP.get(URI(ex.response['location']))
        end
      end

      private

      def set_attributes(attributes, response)
        set_attrs(attributes, false)
        return if response.body.nil? || response.body.length < 2

        json = self.class.parse_json(response.body)
        attachment = json[0]

        set_attrs(attachment)
      end
    end
  end
end
