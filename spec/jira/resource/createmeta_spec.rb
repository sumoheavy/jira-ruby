require 'spec_helper'

describe JIRA::Resource::Createmeta do
  let(:client) {
    double(
      'client',
      :options => {
        :rest_base_path => '/jira/rest/api/2'
      }
    )
  }

  let(:response) {
    double(
      'response',
      :body => '{"expand":"projects","projects":[{"self":"http://localhost:2029/rest/api/2/project/TST","id":"10200","key":"test_key","name":"Test Name"}]}'
    )
  }

  describe 'general' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta').and_return(response)
      JIRA::Resource::Createmeta.all(client)
    end

    it 'should query correct url with `expand` parameter' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields').and_return(response)
      JIRA::Resource::Createmeta.all(client, :expand => 'projects.issuetypes.fields')
    end

    it 'should query correct url with `foo` parameter' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?foo=bar').and_return(response)
      JIRA::Resource::Createmeta.all(client, :foo => 'bar')
    end

    it 'should return an array of createmeta objects' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta').and_return(response)
      createmetas = JIRA::Resource::Createmeta.all(client)
      expect(createmetas).to be_an Array
      createmeta = createmetas.first
      expect(createmeta.id).to eq '10200'
      expect(createmeta.key).to eq 'test_key'
      expect(createmeta.name).to eq 'Test Name'
    end
  end

  describe 'projectKeys' do
    it 'should query correct url when only one `projectKeys` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectKeys=PROJECT_1').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectKeys => 'PROJECT_1',
      )
    end

    it 'should query correct url when multiple `projectKeys` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectKeys=PROJECT_1%2CPROJECT_2').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectKeys => ['PROJECT_1', 'PROJECT_2'],
      )
    end

    it 'should query correct url when only one `projectKeys` given as Project' do
      prj = JIRA::Resource::Project.new(client)
      allow(prj).to receive(:key).and_return('PRJ')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectKeys=PRJ').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectKeys => prj,
      )
    end

    it 'should query correct url when multiple `projectKeys` given as Project' do
      prj_1 = JIRA::Resource::Project.new(client)
      allow(prj_1).to receive(:key).and_return('PRJ_1')
      prj_2 = JIRA::Resource::Project.new(client)
      allow(prj_2).to receive(:key).and_return('PRJ_2')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectKeys=PRJ_2%2CPRJ_1').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectKeys => [prj_2, prj_1],
      )
    end

    it 'should query correct url when multiple `projectKeys` given as different types' do
      prj_5 = JIRA::Resource::Project.new(client)
      allow(prj_5).to receive(:key).and_return('PRJ_5')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectKeys=PROJECT_1%2CPRJ_5').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectKeys => ['PROJECT_1', prj_5],
      )
    end
  end


  describe 'projectIds' do
    it 'should query correct url when only one `projectIds` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectIds=10101').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectIds => '10101',
      )
    end

    it 'should query correct url when multiple `projectIds` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectIds=10101%2C20202').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectIds => ['10101', '20202'],
      )
    end

    it 'should query correct url when only one `projectIds` given as Project' do
      prj = JIRA::Resource::Project.new(client)
      allow(prj).to receive(:id).and_return('30303')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectIds=30303').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectIds => prj,
      )
    end

    it 'should query correct url when multiple `projectIds` given as Project' do
      prj_1 = JIRA::Resource::Project.new(client)
      allow(prj_1).to receive(:id).and_return('30303')
      prj_2 = JIRA::Resource::Project.new(client)
      allow(prj_2).to receive(:id).and_return('50505')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectIds=50505%2C30303').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectIds => [prj_2, prj_1],
      )
    end

    it 'should query correct url when multiple `projectIds` given as different types' do
      prj_5 = JIRA::Resource::Project.new(client)
      allow(prj_5).to receive(:id).and_return('60606')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?projectIds=10101%2C60606').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :projectIds => ['10101', prj_5],
      )
    end
  end


  describe 'issuetypeNames' do
    it 'should query correct url when only one `issuetypeNames` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeNames=Feature').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeNames => 'Feature',
      )
    end

    it 'should query correct url when multiple `issuetypeNames` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeNames=Feature%2CBug').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeNames => ['Feature', 'Bug'],
      )
    end

    it 'should query correct url when only one `issuetypeNames` given as Issuetype' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:name).and_return('Epic')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeNames=Epic').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeNames => issue_type,
      )
    end

    it 'should query correct url when multiple `issuetypeNames` given as Issuetype' do
      issue_type_1 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_1).to receive(:name).and_return('Epic')
      issue_type_2 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_2).to receive(:name).and_return('Sub-Task')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeNames=Sub-Task%2CEpic').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeNames => [issue_type_2, issue_type_1],
      )
    end

    it 'should query correct url when multiple `issuetypeNames` given as different types' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:name).and_return('Epic')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeNames=Feature%2CEpic').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeNames => ['Feature', issue_type],
      )
    end
  end


  describe 'issuetypeIds' do
    it 'should query correct url when only one `issuetypeIds` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeIds=10101').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeIds => '10101',
      )
    end

    it 'should query correct url when multiple `issuetypeIds` given as string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeIds=10101%2C20202').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeIds => ['10101', '20202'],
      )
    end

    it 'should query correct url when only one `issuetypeIds` given as Issuetype' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:id).and_return('30303')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeIds=30303').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeIds => issue_type,
      )
    end

    it 'should query correct url when multiple `issuetypeIds` given as Issuetype' do
      issue_type_1 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_1).to receive(:id).and_return('30303')
      issue_type_2 = JIRA::Resource::Issuetype.new(client)
      allow(issue_type_2).to receive(:id).and_return('50505')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeIds=50505%2C30303').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeIds => [issue_type_2, issue_type_1],
      )
    end

    it 'should query correct url when multiple `issuetypeIds` given as different types' do
      issue_type = JIRA::Resource::Issuetype.new(client)
      allow(issue_type).to receive(:id).and_return('30303')

      expect(client).to receive(:get).with('/jira/rest/api/2/issue/createmeta?issuetypeIds=10101%2C30303').and_return(response)
      JIRA::Resource::Createmeta.all(
        client,
        :issuetypeIds => ['10101', issue_type],
      )
    end
  end
end
