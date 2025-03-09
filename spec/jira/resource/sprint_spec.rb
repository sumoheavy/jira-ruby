require 'spec_helper'

describe JIRA::Resource::Sprint do
  let(:client) do
    client = double(options: { rest_base_path: '/jira/rest/api/2', context_path: '/jira' })
    allow(client).to receive(:Sprint).and_return(JIRA::Resource::SprintFactory.new(client))
    client
  end
  let(:sprint) { described_class.new(client) }
  let(:agile_sprint_path) { "/jira/rest/agile/1.0/sprint/#{sprint.id}" }
  let(:response) { double }

  describe 'get_sprint_details' do
    let(:sprint) { described_class.find(client, '1') }

    it 'check each of the date attributes' do
      allow(client).to receive(:get).and_return(double(body: get_mock_response('sprint/1.json')))

      expect(sprint.start_date).to eq Date.parse('2024-01-01T03:20:00.000Z')
      expect(sprint.end_date).to eq Date.parse('2024-01-15T03:20:00.000Z')
      expect(sprint.complete_date).to eq Date.parse('2024-01-16T03:48:00.000Z')
    end
  end

  describe '::find' do
    let(:response) { double('Response', body: '{"some_detail":"some detail"}') }

    it 'fetches the sprint from JIRA' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/111').and_return(response)
      expect(described_class.find(client, '111')).to be_a(described_class)
    end
  end

  describe 'peristence' do
    describe '#save' do
      let(:instance_attrs) { { start_date: '2016-06-01' } }

      before do
        sprint.attrs = instance_attrs
      end

      context 'when attributes are specified' do
        let(:given_attrs) { { start_date: '2016-06-10' } }

        it 'calls save on the super class with the given attributes & agile url' do
          expect_any_instance_of(JIRA::Base).to receive(:save).with(given_attrs, agile_sprint_path)

          sprint.save(given_attrs)
        end
      end

      context 'when attributes are not specified' do
        it 'calls save on the super class with the instance attributes & agile url' do
          expect_any_instance_of(JIRA::Base).to receive(:save).with(instance_attrs, agile_sprint_path)

          sprint.save
        end
      end

      context 'when providing the path argument' do
        it 'ignores it' do
          expect_any_instance_of(JIRA::Base).to receive(:save).with(instance_attrs, agile_sprint_path)

          sprint.save({}, 'mavenlink.com')
        end
      end
    end

    describe '#save!' do
      let(:instance_attrs) { { start_date: '2016-06-01' } }

      before do
        sprint.attrs = instance_attrs
      end

      context 'when attributes are specified' do
        let(:given_attrs) { { start_date: '2016-06-10' } }

        it 'calls save! on the super class with the given attributes & agile url' do
          expect_any_instance_of(JIRA::Base).to receive(:save!).with(given_attrs, agile_sprint_path)

          sprint.save!(given_attrs)
        end
      end

      context 'when attributes are not specified' do
        it 'calls save! on the super class with the instance attributes & agile url' do
          expect_any_instance_of(JIRA::Base).to receive(:save!).with(instance_attrs, agile_sprint_path)

          sprint.save!
        end
      end

      context 'when providing the path argument' do
        it 'ignores it' do
          expect_any_instance_of(JIRA::Base).to receive(:save!).with(instance_attrs, agile_sprint_path)

          sprint.save!({}, 'mavenlink.com')
        end
      end
    end

    context 'when an issue exists' do
      let(:issue_id) { 1001 }
      let(:post_issue_path) do
        described_class.agile_path(client, sprint.id)
        '/jira/rest/agile/1.0/sprint//issue'
      end
      let(:issue) do
        issue = double
        allow(issue).to receive(:id).and_return(issue_id)
        issue
      end
      let(:post_issue_input) do
        { issues: [issue.id] }
      end

      describe '#add_issu' do
        context 'when an issue is passed' do
          it 'posts with the issue id' do
            expect(client).to receive(:post).with(post_issue_path, post_issue_input.to_json)

            sprint.add_issue(issue)
          end
        end
      end
    end

    context 'when multiple issues exist' do
      let(:issue_ids) { [1001, 1012] }
      let(:post_issue_path) do
        described_class.agile_path(client, sprint.id)
        '/jira/rest/agile/1.0/sprint//issue'
      end
      let(:issues) do
        issue_ids.map do |issue_id|
          issue = double
          allow(issue).to receive(:id).and_return(issue_id)
          issue
        end
      end
      let(:post_issue_input) do
        { issues: issue_ids }
      end

      describe '#add_issues' do
        context 'when an issue is passed' do
          it 'posts with the issue id' do
            expect(client).to receive(:post).with(post_issue_path, post_issue_input.to_json)

            sprint.add_issues(issues)
          end
        end
      end
    end
  end
end
