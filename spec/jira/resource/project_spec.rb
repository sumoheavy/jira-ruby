require 'spec_helper'

describe JIRA::Resource::Project do
  let(:client) do
    double('client', options: {
             rest_base_path: '/jira/rest/api/2'
           })
  end

  describe 'relationships' do
    subject do
      described_class.new(client, attrs: {
                            'lead' => { 'foo' => 'bar' },
                                    'issueTypes' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }],
                                    'versions' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }]
                          })
    end

    it 'has the correct relationships' do
      expect(subject).to have_one(:lead, JIRA::Resource::User)
      expect(subject.lead.foo).to eq('bar')

      expect(subject).to have_many(:issuetypes, JIRA::Resource::Issuetype)
      expect(subject.issuetypes.length).to eq(2)

      expect(subject).to have_many(:versions, JIRA::Resource::Version)
      expect(subject.versions.length).to eq(2)
    end
  end

  describe 'issues' do
    subject do
      described_class.new(client, attrs: {
                            'key' => 'test'
                          })
    end

    it 'returns issues' do
      response_body = '{"expand":"schema,names","startAt":0,"maxResults":1,"total":1,"issues":[{"expand":"editmeta,renderedFields,transitions,changelog,operations","id":"53062","self":"/rest/api/2/issue/53062","key":"test key","fields":{"summary":"test summary"}}]}' # rubocop:disable Layout/LineLength
      response = double('response',
                        body: response_body)
      issue_factory = double('issue factory')

      expect(client).to receive(:get)
        .with('/jira/rest/api/2/search?jql=project%3D%22test%22')
        .and_return(response)
      expect(client).to receive(:Issue).and_return(issue_factory)
      expect(issue_factory).to receive(:build)
        .with(JSON.parse(response_body)['issues'][0])
      subject.issues
    end

    context 'with changelog' do
      it 'returns issues' do
        response_body = '{"expand":"schema,names","startAt":0,"maxResults":1,"total":1,"issues":[{"expand":"editmeta,renderedFields,transitions,changelog,operations","id":"53062","self":"/rest/api/2/issue/53062","key":"test key","fields":{"summary":"test summary"},"changelog":{}}]}' # rubocop:disable Layout/LineLength
        response = double('response',
                          body: response_body)
        issue_factory = double('issue factory')

        expect(client).to receive(:get)
          .with('/jira/rest/api/2/search?jql=project%3D%22test%22&expand=changelog&startAt=1&maxResults=100')
          .and_return(response)
        expect(client).to receive(:Issue).and_return(issue_factory)
        expect(issue_factory).to receive(:build)
          .with(JSON.parse(response_body)['issues'][0])
        subject.issues(expand: 'changelog', startAt: 1, maxResults: 100)
      end
    end
  end

  describe 'users' do
    let(:project) { described_class.new(client, attrs: { 'key' => project_key }) }
    let(:project_key) { SecureRandom.hex }
    let(:response) { double('response', body: '[{}]') }

    context 'pagination' do
      before do
        user_factory = double('user factory')
        expect(client).to receive(:User).and_return(user_factory)
        expect(user_factory).to receive(:build).with(any_args)
      end

      it 'doesn\'t use pagination parameters by default' do
        expect(client).to receive(:get)
          .with("/jira/rest/api/2/user/assignable/search?project=#{project_key}")
          .and_return(response)

        project.users
      end

      it 'accepts start_at option' do
        start_at = rand(1000)

        expect(client).to receive(:get)
          .with("/jira/rest/api/2/user/assignable/search?project=#{project_key}&startAt=#{start_at}")
          .and_return(response)

        project.users(start_at:)
      end

      it 'accepts max_results option' do
        max_results = rand(1000)

        expect(client).to receive(:get)
          .with("/jira/rest/api/2/user/assignable/search?project=#{project_key}&maxResults=#{max_results}")
          .and_return(response)

        project.users(max_results:)
      end

      it 'accepts start_at and max_results options' do
        start_at = rand(1000)
        max_results = rand(1000)

        expect(client).to receive(:get)
          .with("/jira/rest/api/2/user/assignable/search?project=#{project_key}&startAt=#{start_at}&maxResults=#{max_results}") # rubocop:disable Layout/LineLength
          .and_return(response)

        project.users(start_at:, max_results:)
      end
    end
  end
end
