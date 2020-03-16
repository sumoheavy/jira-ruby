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

  describe '#save' do
    subject { attachment.save('file' => path_to_file) }
    let(:path_to_file) { './spec/mock_responses/issue.json' }
    let(:response) do
      double(
        body: [
          {
            "id": 10_001,
            "self": 'http://www.example.com/jira/rest/api/2.0/attachments/10000',
            "filename": 'picture.jpg',
            "created": '2017-07-19T12:23:06.572+0000',
            "size": 23_123,
            "mimeType": 'image/jpeg'
          }
        ].to_json
      )
    end
    let(:issue) { JIRA::Resource::Issue.new(client) }

    before do
      allow(client).to receive(:post_multipart).and_return(response)
    end

    it 'successfully update the attachment' do
      subject

      expect(attachment.filename).to eq 'picture.jpg'
      expect(attachment.mimeType).to eq 'image/jpeg'
      expect(attachment.size).to eq 23_123
    end
  end

  describe '#save!' do
    subject { attachment.save!('file' => path_to_file) }

    let(:path_to_file) { './spec/mock_responses/issue.json' }
    let(:response) do
      double(
        body: [
          {
            "id": 10_001,
            "self": 'http://www.example.com/jira/rest/api/2.0/attachments/10000',
            "filename": 'picture.jpg',
            "created": '2017-07-19T12:23:06.572+0000',
            "size": 23_123,
            "mimeType": 'image/jpeg'
          }
        ].to_json
      )
    end
    let(:issue) { JIRA::Resource::Issue.new(client) }

    before do
      allow(client).to receive(:post_multipart).and_return(response)
    end

    it 'successfully update the attachment' do
      subject

      expect(attachment.filename).to eq 'picture.jpg'
      expect(attachment.mimeType).to eq 'image/jpeg'
      expect(attachment.size).to eq 23_123
    end

    context 'when passing in a symbol as file key' do
      subject { attachment.save!(file: path_to_file) }

      it 'successfully update the attachment' do
        subject

        expect(attachment.filename).to eq 'picture.jpg'
        expect(attachment.mimeType).to eq 'image/jpeg'
        expect(attachment.size).to eq 23_123
      end
    end
  end
end
