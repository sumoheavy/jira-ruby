require 'net/http/post/multipart'
require 'open-uri'

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

      def download_file(headers = {}, &block)
        default_headers = client.options[:default_headers]
        URI.open(content, default_headers.merge(headers), &block)
      end

      def download_contents(headers = {})
        download_file(headers) do |file|
          file.read
        end
      end

      def save!(attrs, path = url)
        file = attrs['file'] || attrs[:file] # Keep supporting 'file' parameter as a string for backward compatibility
        mime_type = attrs[:mimeType] || 'application/binary'

        headers = { 'X-Atlassian-Token' => 'nocheck' }
        data = { 'file' => UploadIO.new(file, mime_type, file) }

        response = client.post_multipart(path, data , headers)

        set_attributes(attrs, response)

        @expanded = false
        true
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
