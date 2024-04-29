require 'spec_helper'

describe JIRA::Resource::Attachment do
  subject(:attachment) do
    JIRA::Resource::Attachment.new(
        client,
        issue: JIRA::Resource::Issue.new(client),
        attrs: { 'author' => { 'foo' => 'bar' } }
    )
  end

  let(:client) do
    double(
      'client',
      options: {
        rest_base_path: '/jira/rest/api/2'
      },
      request_client: double(
        options: {
          username: 'username',
          password: 'password'
        }
      )
    )
  end

  describe 'relationships' do
    it 'has an author' do
      expect(subject).to have_one(:author, JIRA::Resource::User)
    end

    it 'has the correct author name' do
      expect(subject.author.foo).to eq('bar')
    end
  end

  describe '.meta' do
    subject { JIRA::Resource::Attachment.meta(client) }

    let(:response) do
      double(
          'response',
          body: '{"enabled":true,"uploadLimit":10485760}'
      )
    end

    it 'returns meta information about attachment upload' do
      expect(client).to receive(:get).with('/jira/rest/api/2/attachment/meta').and_return(response)

      subject
    end

    context 'the factory delegates correctly' do
      subject { JIRA::Resource::AttachmentFactory.new(client) }

      it 'delegates #meta to to target class' do
        expect(subject).to respond_to(:meta)
      end
    end
  end

  context 'there is an attachment on an issue' do
    let(:client) do
      JIRA::Client.new(username: 'username', password: 'password', auth_type: :basic, use_ssl: false )
    end
    let(:attachment_file_contents) { 'file contents' }
    let(:file_target) { double(read: :attachment_file_contents) }
    let(:attachment_url) { "https:jirahost/secure/attachment/32323/myfile.txt" }
    subject(:attachment) do
      JIRA::Resource::Attachment.new(
        client,
        issue: JIRA::Resource::Issue.new(client),
        attrs: { 'author' => { 'foo' => 'bar' }, 'content' => attachment_url }
      )
    end

    describe '.download_file' do
      it 'passes file object to block' do
        expect(URI).to receive(:open).with(attachment_url, anything).and_yield(file_target)

        attachment.download_file do |file|
          expect(file).to eq(file_target)
        end

      end
    end

    describe '.download_contents' do
      it 'downloads the file contents as a string' do
        expect(URI).to receive(:open).with(attachment_url, anything).and_return(attachment_file_contents)

        result_str = attachment.download_contents

        expect(result_str).to eq(attachment_file_contents)
      end
    end
  end

  context 'when there is a local file' do
    let(:file_name) { 'short.txt' }
    let(:file_size) { 11 }
    let(:file_mime_type) { 'text/plain' }
    let(:path_to_file) { "./spec/data/files/#{file_name}" }
    let(:response) do
      double(
        body: [
          {
            "id": 10_001,
            "self": 'http://www.example.com/jira/rest/api/2.0/attachments/10000',
            "filename": file_name,
            "created": '2017-07-19T12:23:06.572+0000',
            "size": file_size,
            "mimeType": file_mime_type
          }
        ].to_json
      )
    end
    let(:issue) { JIRA::Resource::Issue.new(client) }

    describe '#save' do
      subject { attachment.save('file' => path_to_file) }

      before do
        allow(client).to receive(:post_multipart).and_return(response)
      end

      it 'successfully update the attachment' do
        subject

        expect(attachment.filename).to eq file_name
        expect(attachment.mimeType).to eq file_mime_type
        expect(attachment.size).to eq file_size
      end
      context 'when using custom client headers' do
        subject(:bearer_attachment) do
          JIRA::Resource::Attachment.new(
            bearer_client,
            issue: JIRA::Resource::Issue.new(bearer_client),
            attrs: { 'author' => { 'foo' => 'bar' } }
          )
        end
        let(:default_headers_given) { { 'authorization' => "Bearer 83CF8B609DE60036A8277BD0E96135751BBC07EB234256D4B65B893360651BF2" } }
        let(:bearer_client) do
          JIRA::Client.new(username: 'username', password: 'password', auth_type: :basic, use_ssl: false,
                           default_headers: default_headers_given )
        end
        let(:merged_headers) do
          {"Accept"=>"application/json", "X-Atlassian-Token"=>"nocheck"}.merge(default_headers_given)
        end

        it 'passes the custom headers' do
          expect(bearer_client.request_client).to receive(:request_multipart).with(anything, anything, merged_headers).and_return(response)

          bearer_attachment.save('file' => path_to_file)

        end
      end

    end

    describe '#save!' do
    subject { attachment.save!('file' => path_to_file) }

      before do
        allow(client).to receive(:post_multipart).and_return(response)
      end

      it 'successfully update the attachment' do
        subject

        expect(attachment.filename).to eq file_name
        expect(attachment.mimeType).to eq file_mime_type
        expect(attachment.size).to eq file_size
      end

      context 'when passing in a symbol as file key' do
        subject { attachment.save!(file: path_to_file) }

        it 'successfully update the attachment' do
          subject

          expect(attachment.filename).to eq file_name
          expect(attachment.mimeType).to eq file_mime_type
          expect(attachment.size).to eq file_size
        end
      end

      context 'when using custom client headers' do
        subject(:bearer_attachment) do
          JIRA::Resource::Attachment.new(
            bearer_client,
            issue: JIRA::Resource::Issue.new(bearer_client),
            attrs: { 'author' => { 'foo' => 'bar' } }
          )
        end
        let(:default_headers_given) { { 'authorization' => "Bearer 83CF8B609DE60036A8277BD0E96135751BBC07EB234256D4B65B893360651BF2" } }
        let(:bearer_client) do
          JIRA::Client.new(username: 'username', password: 'password', auth_type: :basic, use_ssl: false,
                           default_headers: default_headers_given )
        end
        let(:merged_headers) do
          {"Accept"=>"application/json", "X-Atlassian-Token"=>"nocheck"}.merge(default_headers_given)
        end

        it 'passes the custom headers' do
          expect(bearer_client.request_client).to receive(:request_multipart).with(anything, anything, merged_headers).and_return(response)

          bearer_attachment.save!('file' => path_to_file)

        end
      end
    end
  end
end
