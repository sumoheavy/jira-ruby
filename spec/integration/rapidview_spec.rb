require 'spec_helper'

describe JIRA::Resource::RapidView do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '1' }

    let(:expected_collection_length) { 1 }

    let(:expected_attributes) {
      {
        'id' => 1,
        'name' => 'SAMPLEPROJECT',
        'canEdit' => true,
        'sprintSupportEnabled' => true
      }
    }

    it_should_behave_like 'a resource'
    # TODO@Anton: Add json file
    # it_should_behave_like 'a resource with a singular GET endpoint'

    describe 'GET all rapidviews' do
      let(:client) { client }
      let(:site_url) { site_url }

      before(:each) do
        stub_request(:get, site_url + '/jira/rest/greenhopper/1.0/rapidview').
        to_return(:status => 200, :body => get_mock_response('rapidview.json'))

      end
      it_should_behave_like 'a resource with a collection GET endpoint'
    end

    describe 'issues' do
      it 'should return all the issues' do
        stub_request(
          :get,
          site_url +
          '/jira/rest/greenhopper/1.0/xboard/plan/backlog/data?rapidViewId=1'
        ).to_return(
          :status => 200,
          :body => get_mock_response('rapidview/SAMPLEPROJECT.issues.json')
        )
        stub_request(:get, "http://localhost:2990/jira/rest/api/3/search/jql?jql=id%20IN(10000,%2010001)%20AND%20sprint%20IS%20NOT%20EMPTY")
        .with(headers: {
        'Accept'=>'application/json',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>/OAuth .*/,
        'User-Agent'=>'OAuth gem v0.5.14'
        })
      .to_return(status: 200, body: get_mock_response('rapidview/SAMPLEPROJECT.issues.full.json'), headers: {})
        stub_request(
          :get,
          "http://localhost:2990/jira/rest/api/3/search/jql?jql=id%20IN(10001,%2010000)"
        ).with(headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>/OAuth .*/,
          'User-Agent'=>'OAuth gem v0.5.14'
        })
        .to_return(status: 200, body: get_mock_response('rapidview/SAMPLEPROJECT.issues.full.json'), headers: {})
        stub_request(
          :get,
          'http://foo:bar@localhost:2990' + '/jira/rest/api/3/search/jql?jql=id IN(10000, 10001)%20AND%20sprint%20IS%20NOT%20EMPTY'
        ).to_return(
          :status => 200,
          :body => get_mock_response('rapidview/SAMPLEPROJECT.issues.full.json')
        )

        stub_request(
          :get,
          'http://foo:bar@localhost:2990' + '/jira/rest/api/3/search/jql?jql=id IN(10001, 10000)'
        ).to_return(
          :status => 200,
          :body => get_mock_response('rapidview/SAMPLEPROJECT.issues.full.json')
        )

        subject = client.RapidView.build('id' => 1)
        issues = subject.issues
        expect(issues["issues"].length).to eq(2)
        issues["issues"].each do |issue|
          expect(issue.class).to eq(JIRA::Resource::Issue)
          expect(issue.expanded?).to be_falsey
        end
      end
    end
  end
end
