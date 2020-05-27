require 'spec_helper'

describe JIRA::Resource::Sprint do
  let(:client) do
    client = double(options: { site: 'https://foo.bar.com', context_path: '/jira' })
    allow(client).to receive(:Sprint).and_return(JIRA::Resource::SprintFactory.new(client))
    client
  end
  let(:sprint) { described_class.new(client) }
  let(:agile_sprint_path) { "#{sprint.client.options[:context_path]}/rest/agile/1.0/sprint/#{sprint.id}" }

  describe '::find' do
    let(:response) { double('Response', body: '{"some_detail":"some detail"}') }

    it 'fetches the sprint from JIRA' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/111').and_return(response)
      expect(JIRA::Resource::Sprint.find(client, '111')).to be_a(JIRA::Resource::Sprint)
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
  end
end
