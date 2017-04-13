module JIRA
  module Resource
    class AttachmentFactory < JIRA::BaseFactory # :nodoc:
    end

    class Attachment < JIRA::Base
      belongs_to :issue

      def self.endpoint_name
        'attachments'
      end

      def save!(attrs)
        path           = attrs['file_path']
        name           = attrs['file_name'] || path
        file           = File.new path
        io             = UploadIO.new file, 'application/binary', name
        data           = { 'file' => io }
        headers        = { 'X-Atlassian-Token' => 'nocheck' }
        request        = Net::HTTP::Post::Multipart.new url, data, headers
        request_client = client.request_client
        options        = client.request_client.options

        request.basic_auth options[:username], options[:password]

        response = request_client.basic_auth_http_conn.request request

        set_attrs attrs, false

        unless response.body.nil? || response.body.length < 2
          json       = self.class.parse_json(response.body)
          attachment = json[0]

          set_attrs attachment
        end

        @expanded = false

        true
      end
    end
  end
end
