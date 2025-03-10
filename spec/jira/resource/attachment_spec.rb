require 'spec_helper'

describe JIRA::Resource::Attachment do
  subject(:attachment) do
    described_class.new(
      client,
      issue: JIRA::Resource::Issue.new(client, attrs: { 'id' => issue_id }),
      attrs: { 'author' => { 'foo' => 'bar' }, 'id' => attachment_id }
    )
  end

  let(:issue_id) { 27_676 }
  let(:attachment_id) { 30_076 }
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
    subject { described_class.meta(client) }

    let(:response) do
      double(
        'response',
        body: '{"enabled":true,"uploadLimit":10485760}'
      )
    end

    context 'when returning meta information' do
      it 'returns meta information about attachment upload' do
        expect(client).to receive(:get).with('/jira/rest/api/2/attachment/meta').and_return(response)

        result = subject

        expect(result).to be_kind_of(Hash)
      end
    end

    context 'the factory delegates correctly' do
      subject { JIRA::Resource::AttachmentFactory.new(client) }

      it 'delegates #meta to to target class' do
        expect(subject).to respond_to(:meta)
      end
    end
  end

  context 'there is an attachment on an issue' do
    subject(:attachment) do
      described_class.new(
        client,
        issue: JIRA::Resource::Issue.new(client),
        attrs: { 'author' => { 'foo' => 'bar' }, 'content' => attachment_url }
      )
    end

    let(:attachment_url) { 'https://localhost:2990/secure/attachment/32323/myfile.txt' }
    let(:client) do
      JIRA::Client.new(username: 'username', password: 'password', auth_type: :basic, use_ssl: false)
    end
    let(:attachment_file_contents) { 'file contents' }
    let(:issue_id) { 3232 }
    let(:issue) { JIRA::Resource::Issue.new(client, attrs: { 'id' => issue_id }) }

    before do
      stub_request(:get, attachment_url).to_return(body: attachment_file_contents)
    end

    describe '.download_file' do
      context 'when passing file object to block' do
        it 'passes file object to block' do
          expect(URI).to receive(:parse).with(attachment_url).and_call_original

          attachment.download_file do |file|
            expect(file.read).to eq(attachment_file_contents)
          end
        end
      end
    end

    describe '.download_contents' do
      it 'downloads the file contents as a string' do
        expect(URI).to receive(:parse).with(attachment_url).and_call_original

        expect(attachment.download_contents).to eq(attachment_file_contents)
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
            id: 10_001,
            self: 'http://www.example.com/jira/rest/api/2.0/attachments/10000',
            filename: file_name,
            created: '2017-07-19T12:23:06.572+0000',
            size: file_size,
            mimeType: file_mime_type
          }
        ].to_json
      )
    end
    let(:issue) { JIRA::Resource::Issue.new(client, attrs: { 'id' => issue_id }) }

    describe '#save' do
      subject { attachment.save('file' => path_to_file) }

      before do
        allow(client).to receive(:post_multipart).and_return(response)
      end

      it 'successfully update the attachment' do
        expect(client).to receive(:post_multipart).and_return(response).with("/jira/rest/api/2/issue/#{issue.id}/attachments/#{attachment.id}", anything, anything)

        subject

        expect(attachment.filename).to eq file_name
        expect(attachment.mimeType).to eq file_mime_type
        expect(attachment.size).to eq file_size
      end

      context 'when using custom client headers' do
        subject(:bearer_attachment) do
          described_class.new(
            bearer_client,
            issue: JIRA::Resource::Issue.new(bearer_client),
            attrs: { 'author' => { 'foo' => 'bar' } }
          )
        end

        let(:default_headers_given) do
          {
            'authorization' => 'Bearer 83CF8B609DE60036A8277BD0E96135751BBC07EB234256D4B65B893360651BF2'
          }
        end
        let(:bearer_client) do
          JIRA::Client.new(username: 'username', password: 'password', auth_type: :basic, use_ssl: false,
                           default_headers: default_headers_given)
        end
        let(:merged_headers) do
          {
            'Accept' => 'application/json',
            'X-Atlassian-Token' => 'nocheck'
          }.merge(default_headers_given)
        end

        it 'passes the custom headers' do
          expect(bearer_client.request_client).to receive(:request_multipart)
            .with(anything, anything, merged_headers)
            .and_return(response)

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
          described_class.new(
            bearer_client,
            issue: JIRA::Resource::Issue.new(bearer_client),
            attrs: { 'author' => { 'foo' => 'bar' } }
          )
        end

        let(:default_headers_given) { { 'authorization' => 'Bearer 83CF8B609DE60036A8277BD0E96135751BBC07EB234256D4B65B893360651BF2' } }
        let(:bearer_client) do
          JIRA::Client.new(username: 'username', password: 'password', auth_type: :basic, use_ssl: false,
                           default_headers: default_headers_given)
        end
        let(:merged_headers) do
          {
            'Accept' => 'application/json',
            'X-Atlassian-Token' => 'nocheck'
          }.merge(default_headers_given)
        end

        it 'passes the custom headers' do
          expect(bearer_client.request_client).to receive(:request_multipart)
            .with(anything, anything, merged_headers)
            .and_return(response)

          bearer_attachment.save!('file' => path_to_file)
        end
      end
    end
  end

  context 'an attachment is on an issue' do
    describe '#delete' do
      it 'removes the attachment' do
        expect(client).to receive(:delete).with("/jira/rest/api/2/issue/#{issue_id}/attachments/#{attachment_id}")

        attachment.delete
      end
    end
  end
end
