require 'net/http/post/multipart'

module JIRA
  module Resource

    class AttachmentFactory < JIRA::BaseFactory # :nodoc:
      delegate_to_target_class :meta
    end

    class Attachment < JIRA::Base
      belongs_to :issue
      has_one :author, :class => JIRA::Resource::User

      def self.endpoint_name
        'attachments'
      end

      def self.meta(client)
        response = client.get(client.options[:rest_base_path] + '/attachment/meta')
        parse_json(response.body)
      end

      def save!(attrs)
        headers = { 'X-Atlassian-Token' => 'nocheck' }
        data = { 'file' => UploadIO.new(attrs['file'], 'application/binary', attrs['file']) }

        request = Net::HTTP::Post::Multipart.new url, data, headers
        request.basic_auth(client.request_client.options[:username],
                           client.request_client.options[:password])

        response = client.request_client.basic_auth_http_conn.request(request)

        set_attrs(attrs, false)
        unless response.body.nil? || response.body.length < 2
          json = self.class.parse_json(response.body)
          attachment = json[0]

          set_attrs(attachment)
        end

        @expanded = false
        true
      end
    end
  end
end
