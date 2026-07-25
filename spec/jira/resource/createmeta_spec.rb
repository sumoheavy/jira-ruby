require 'spec_helper'

describe JIRA::Resource::Createmeta do
  let(:client) do
    double(
      'client',
      options: {
        rest_base_path: '/jira/rest/api/2'
      }
    )
  end

  let(:response) do
    double(
      'response',
      body: '{"expand":"projects","projects":[' \
            '{"self":"http://localhost:2029/rest/api/2/project/TST",' \
            '"id":"10200","key":"test_key","name":"Test Name"}]}'
    )
  end

  # Expects a GET of the createmeta endpoint, with the given query string appended.
  def expect_createmeta_get(query = '')
    expect(client).to receive(:get).with("/jira/rest/api/2/issue/createmeta#{query}").and_return(response)
  end

  describe 'general' do
    it 'queries correct url without parameters' do
      expect_createmeta_get
      described_class.all(client)
    end

    it 'queries correct url with `expand` parameter' do
      expect_createmeta_get '?expand=projects.issuetypes.fields'
      described_class.all(client, expand: 'projects.issuetypes.fields')
    end

    it 'queries correct url with `foo` parameter' do
      expect_createmeta_get '?foo=bar'
      described_class.all(client, foo: 'bar')
    end

    it 'returns an array of createmeta objects' do
      expect_createmeta_get
      createmetas = described_class.all(client)
      expect(createmetas).to be_an Array
      createmeta = createmetas.first
      expect(createmeta.id).to eq '10200'
      expect(createmeta.key).to eq 'test_key'
      expect(createmeta.name).to eq 'Test Name'
    end
  end

  describe 'projectKeys' do
    it 'queries correct url when only one `projectKeys` given as string' do
      expect_createmeta_get '?projectKeys=PROJECT_1'
      described_class.all(
        client,
        projectKeys: 'PROJECT_1'
      )
    end

    it 'queries correct url when multiple `projectKeys` given as string' do
      expect_createmeta_get '?projectKeys=PROJECT_1%2CPROJECT_2'
      described_class.all(
        client,
        projectKeys: %w[PROJECT_1 PROJECT_2]
      )
    end

    it 'queries correct url when only one `projectKeys` given as Project' do
      prj = JIRA::Resource::Project.new(client)
      allow(prj).to receive(:key).and_return('PRJ')

      expect_createmeta_get '?projectKeys=PRJ'
      described_class.all(
        client,
        projectKeys: prj
      )
    end

    it 'queries correct url when multiple `projectKeys` given as Project' do
      prj_1 = JIRA::Resource::Project.new(client)
      allow(prj_1).to receive(:key).and_return('PRJ_1')
      prj_2 = JIRA::Resource::Project.new(client)
      allow(prj_2).to receive(:key).and_return('PRJ_2')

      expect_createmeta_get '?projectKeys=PRJ_2%2CPRJ_1'
      described_class.all(
        client,
        projectKeys: [prj_2, prj_1]
      )
    end

    it 'queries correct url when multiple `projectKeys` given as different types' do
      prj_5 = JIRA::Resource::Project.new(client)
      allow(prj_5).to receive(:key).and_return('PRJ_5')

      expect_createmeta_get '?projectKeys=PROJECT_1%2CPRJ_5'
      described_class.all(
        client,
        projectKeys: ['PROJECT_1', prj_5]
      )
    end
  end

  describe 'projectIds' do
    it 'queries correct url when only one `projectIds` given as string' do
      expect_createmeta_get '?projectIds=10101'
      described_class.all(
        client,
        projectIds: '10101'
      )
    end

    it 'queries correct url when multiple `projectIds` given as string' do
      expect_createmeta_get '?projectIds=10101%2C20202'
      described_class.all(
        client,
        projectIds: %w[10101 20202]
      )
    end

    it 'queries correct url when only one `projectIds` given as Project' do
      prj = JIRA::Resource::Project.new(client)
      allow(prj).to receive(:id).and_return('30303')

      expect_createmeta_get '?projectIds=30303'
      described_class.all(
        client,
        projectIds: prj
      )
    end

    it 'queries correct url when multiple `projectIds` given as Project' do
      prj_1 = JIRA::Resource::Project.new(client)
      allow(prj_1).to receive(:id).and_return('30303')
      prj_2 = JIRA::Resource::Project.new(client)
      allow(prj_2).to receive(:id).and_return('50505')

      expect_createmeta_get '?projectIds=50505%2C30303'
      described_class.all(
        client,
        projectIds: [prj_2, prj_1]
      )
    end

    it 'queries correct url when multiple `projectIds` given as different types' do
      prj_5 = JIRA::Resource::Project.new(client)
      allow(prj_5).to receive(:id).and_return('60606')

      expect_createmeta_get '?projectIds=10101%2C60606'
      described_class.all(
        client,
        projectIds: ['10101', prj_5]
      )
    end
  end

  describe 'issuetypeNames' do
    it 'queries correct url when only one `issuetypeNames` given as string' do
      expect_createmeta_get '?issuetypeNames=Feature'
      described_class.all(
        client,
        issuetypeNames: 'Feature'
      )
    end

    it 'queries correct url when multiple `issuetypeNames` given as string' do
      expect_createmeta_get '?issuetypeNames=Feature%2CBug'
      described_class.all(
        client,
        issuetypeNames: %w[Feature Bug]
      )
    end

    it 'queries correct url when only one `issuetypeNames` given as Issuetype' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:name).and_return('Epic')

      expect_createmeta_get '?issuetypeNames=Epic'
      described_class.all(
        client,
        issuetypeNames: issue_type
      )
    end

    it 'queries correct url when multiple `issuetypeNames` given as Issuetype' do
      issue_type_1 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_1).to receive(:name).and_return('Epic')
      issue_type_2 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_2).to receive(:name).and_return('Sub-Task')

      expect_createmeta_get '?issuetypeNames=Sub-Task%2CEpic'
      described_class.all(
        client,
        issuetypeNames: [issue_type_2, issue_type_1]
      )
    end

    it 'queries correct url when multiple `issuetypeNames` given as different types' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:name).and_return('Epic')

      expect_createmeta_get '?issuetypeNames=Feature%2CEpic'
      described_class.all(
        client,
        issuetypeNames: ['Feature', issue_type]
      )
    end
  end

  describe 'issuetypeIds' do
    it 'queries correct url when only one `issuetypeIds` given as string' do
      expect_createmeta_get '?issuetypeIds=10101'
      described_class.all(
        client,
        issuetypeIds: '10101'
      )
    end

    it 'queries correct url when multiple `issuetypeIds` given as string' do
      expect_createmeta_get '?issuetypeIds=10101%2C20202'
      described_class.all(
        client,
        issuetypeIds: %w[10101 20202]
      )
    end

    it 'queries correct url when only one `issuetypeIds` given as Issuetype' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:id).and_return('30303')

      expect_createmeta_get '?issuetypeIds=30303'
      described_class.all(
        client,
        issuetypeIds: issue_type
      )
    end

    it 'queries correct url when multiple `issuetypeIds` given as Issuetype' do
      issue_type_1 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_1).to receive(:id).and_return('30303')
      issue_type_2 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_2).to receive(:id).and_return('50505')

      expect_createmeta_get '?issuetypeIds=50505%2C30303'
      described_class.all(
        client,
        issuetypeIds: [issue_type_2, issue_type_1]
      )
    end

    it 'queries correct url when multiple `issuetypeIds` given as different types' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:id).and_return('30303')

      expect_createmeta_get '?issuetypeIds=10101%2C30303'
      described_class.all(
        client,
        issuetypeIds: ['10101', issue_type]
      )
    end
  end
end
