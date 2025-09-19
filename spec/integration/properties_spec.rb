require 'spec_helper'

describe JIRA::Resource::Properties do
  with_each_client do |site_url, client|
    context 'when accessing singular resource' do
      let(:client) { client }
      let(:site_url) { site_url }
      let(:key) { 'xyz' }
      let(:target) { described_class.new(client, attrs: { 'key' => 'xyz' }, issue_id: '10002') }
      let(:belongs_to) { JIRA::Resource::Issue.new(client, attrs: { 'id' => '10002' }) }
      let(:expected_attributes) { { 'key' => key, 'value' => 'supercalifragilistic' } }
      let(:attributes_for_put) { { 'value' => 'expialidocious' } }
      let(:expected_attributes_from_put) { { 'key' => key, 'value' => 'expialidocious' } }

      it_behaves_like 'a resource'
      it_behaves_like 'a resource with a singular GET endpoint'
      it_behaves_like 'a resource with a DELETE endpoint'
      it_behaves_like 'a resource with a PUT endpoint'
    end

    context 'when accessing collection' do
      let(:client) { client }
      let(:site_url) { site_url }
      let(:key) { 'xyz' }
      let(:belongs_to) { JIRA::Resource::Issue.new(client, attrs: { 'id' => '10002' }) }
      let(:expected_collection_length) { 2 }
      let(:expected_attributes) { { 'key' => key, 'value' => 'supercalifragilistic' } }

      before do
        ## Since properties collections do subsequent queries on each individual properties records,
        ## we need to additionally define stub requests for each of the individual records
        additional_targets = [
          described_class.new(client, attrs: { 'key' => 'foo' }, issue_id: '10002'),
          described_class.new(client, attrs: { 'key' => 'xyz' }, issue_id: '10002')
        ]
        additional_targets.each do |target|
          req_url = site_url + target.url
          stub_request(:get, req_url).to_return(status: 200, body: get_mock_from_url(:get, req_url))
        end
      end

      it_behaves_like 'a resource with a collection GET endpoint'
    end
  end
end
