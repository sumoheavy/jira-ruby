require 'spec_helper'

describe JIRA::Resource::RapidView do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '1' }

    let(:expected_collection_length) { 1 }

    let(:expected_attributes) do
      {
        'id' => 1,
        'name' => 'SAMPLEPROJECT',
        'canEdit' => true,
        'sprintSupportEnabled' => true
      }
    end

    it_behaves_like 'a resource'
    # TODO@Anton: Add json file
    # it_should_behave_like 'a resource with a singular GET endpoint'

    describe 'GET all rapidviews' do
      let(:client) { client }
      let(:site_url) { site_url }

      before(:each) do
        stub_request(:get, "#{site_url}/jira/rest/greenhopper/1.0/rapidview")
          .to_return(status: 200, body: get_mock_response('rapidview.json'))
      end
      it_behaves_like 'a resource with a collection GET endpoint'
    end

    describe 'issues' do
      it 'returns all the issues' do
        stub_request(
          :get,
          "#{site_url}/jira/rest/greenhopper/1.0/xboard/plan/backlog/data?rapidViewId=1"
        ).to_return(
          status: 200,
          body: get_mock_response('rapidview/SAMPLEPROJECT.issues.json')
        )

        stub_request(
          :get,
          "#{site_url}/jira/rest/api/2/search?jql=id IN(10001, 10000)"
        ).to_return(
          status: 200,
          body: get_mock_response('rapidview/SAMPLEPROJECT.issues.full.json')
        )

        stub_request(
          :get,
          "#{site_url}/jira/rest/api/2/search?jql=id IN(10000, 10001) AND sprint IS NOT EMPTY"
        ).to_return(
          status: 200,
          body: get_mock_response('rapidview/SAMPLEPROJECT.issues.full.json')
        )

        subject = client.RapidView.build('id' => 1)
        issues = subject.issues
        expect(issues.length).to eq(2)

        issues.each do |issue|
          expect(issue.class).to eq(JIRA::Resource::Issue)
          expect(issue.expanded?).to be_falsey
        end
      end
    end
  end
end
