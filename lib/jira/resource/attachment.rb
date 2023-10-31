# frozen_string_literal: true

require 'net/http/post/multipart'
require 'open-uri'

module JIRA
  module Resource
    class AttachmentFactory < JIRA::BaseFactory # :nodoc:
      delegate_to_target_class :meta
    end


    # This class provides the Attachment object <-> REST mapping for JIRA::Resource::Attachment derived class,
    # i.e. the Create, Retrieve, Update, Delete lifecycle methods.
    #
    # == Lifecycle methods
    #
    # === Retrieving a single attachment by Issue and attachment id
    #
    #     issue =  JIRA::Resource::Issue.find(client, 'SUP-3000', { fields: 'attachment' } )
    #     attachments = issue.attachments.find(30076)
    #     attachment = attachments.first
    #
    # === Retrieving file contents of attachment
    #
    #     content = URI.open(attachment.content).read
    #
    # === Adding an attachment to an issue
    #
    #     Dir.mktmpdir do |dir|
    #       path = File.join(dir, filename)
    #       IO.copy_stream(file.path, path)
    #
    #       issue =  JIRA::Resource::Issue.find(client, 'SUP-3000', { fields: 'attachment' } )
    #       attachment = issue.attachments.build
    #       attachment.save!( { file: path, mimeType: content_type } )
    #     end
    #
    #
    #
    # @!attribute [r] self
    #   @return [String] URL to JSON of this attachment
    # @!attribute [r] filename
    #   @return [String] the filename
    # @!attribute [r] author
    #   @return [JIRA::Resource::User] the user who created the attachment
    # @!attribute [r] created
    #   @return [String] timestamp when the attachment was created
    # @!attribute [r] size
    #   @return [Integer] the file size
    # @!attribute [r] mimeType
    #   @return [String] MIME of the content type
    # @!attribute [r] content
    #   @return [String] URI to download the contents of the attachment
    #
    class Attachment < JIRA::Base
      belongs_to :issue
      has_one :author, class: JIRA::Resource::User

      def self.endpoint_name
        'attachments'
      end

      def self.meta(client)
        response = client.get("#{client.options[:rest_base_path]}/attachment/meta")
        parse_json(response.body)
      end

      # Opens a file streaming the download of the attachment.
      # @example Write file contents to a file.
      #   File.open('some-filename', 'wb') do |output|
      #     download_file do |file|
      #       IO.copy_stream(file, output)
      #     end
      #   end
      # @example Stream file contents for an HTTP response.
      #   response.headers[ "Content-Type" ] = "application/octet-stream"
      #   download_file do |file|
      #     chunk = file.read(8000)
      #     while chunk.present? do
      #       response.stream.write(chunk)
      #       chunk = file.read(8000)
      #     end
      #   end
      #   response.stream.close
      # @param [Hash] headers Any additional headers to call Jira.
      # @yield |file|
      # @yieldparam [IO] file The IO object streaming the download.
      def download_file(headers = {}, &block)
        default_headers = client.options[:default_headers]
        URI.parse(content).open(default_headers.merge(headers), &block)
      end

      # Downloads the file contents as a string object.
      #
      # Note that this reads the contents into a ruby string in memory.
      # A file might be very large so it is recommend to avoid this unless you are certain about doing so.
      # Use the download_file method instead and avoid calling the read method without a limit.
      #
      # @param [Hash] headers Any additional headers to call Jira.
      # @return [String,NilClass] The file contents.
      def download_contents(headers = {})
        download_file(headers, &:read)
      end

      def save!(attrs, path = url)
        file = attrs['file'] || attrs[:file] # Keep supporting 'file' parameter as a string for backward compatibility
        mime_type = attrs[:mimeType] || 'application/binary'

        headers = { 'X-Atlassian-Token' => 'nocheck' }
        data = { 'file' => Multipart::Post::UploadIO.new(file, mime_type, file) }

        response = client.post_multipart(path, data, headers)

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
