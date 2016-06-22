require 'spec_helper'

describe JIRA::Resource::Field do

  let(:cache) { OpenStruct.new }

  let(:client) do
    client = double(options: {rest_base_path: '/jira/rest/api/2'}  )
    field = JIRA::Resource::FieldFactory.new(client)
    allow(client).to receive(:Field).and_return(field)
    allow(client).to receive(:cache).and_return(cache)
    # info about all fields on the client
    allow(client.Field).to receive(:all).and_return([
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"customfield_10666", "name" => "Priority",   "custom" => true,  "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["cf[10666]","Priority"],         "schema" =>{"type" => "string",    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select","customId" => 10666}}),
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"issuekey",          "name" => "Key",        "custom" => false, "orderable" => false, "navigable" => true, "searchable" => false, "clauseNames" => ["id","issue","issuekey","key"]}),
      JIRA::Resource::Field.new(client, :attrs => {"id" =>"priority",          "name" => "Priority",   "custom" => false, "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["priority"],                     "schema" =>{"type" => "priority",  "system" => "priority"}}),
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"summary",           "name" => "Summary",    "custom" => false, "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["summary"],                      "schema" =>{"type" => "string",    "system" => "summary"}}),
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"issuetype",         "name" => "Issue Type", "custom" => false, "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["issuetype","type"],             "schema" =>{"type" => "issuetype", "system" => "issuetype"}}),
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"customfield_10111", "name" => "SingleWord", "custom" => true,  "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["cf[10111]","SingleWord"],       "schema" =>{"type" => "string",    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select","customId" => 10111}}),
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"customfield_10222", "name" => "Multi Word", "custom" => true,  "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["cf[10222]","Multi Word"],       "schema" =>{"type" => "string",    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select","customId" => 10222}}),
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"customfield_10333", "name" => "Why/N@t",    "custom" => true,  "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["cf[10333]","Why/N@t"],          "schema" =>{"type" => "string",    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select","customId" => 10333}}),
      JIRA::Resource::Field.new(client, :attrs => {'id' =>"customfield_10444", "name" => "SingleWord", "custom" => true,  "orderable" => true,  "navigable" => true, "searchable" => true,  "clauseNames" => ["cf[10444]","SingleWord"],       "schema" =>{"type" => "string",    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select","customId" => 10444}})
    ])
    client
  end

  describe "field_mappings" do

    shared_context "mapped or not" do

      subject {
        JIRA::Resource::Field.new(client, :attrs => {
          'priority' => 1,
          'customfield_10111' => 'data_in_custom_field',
          'customfield_10222' => 'multi word custom name',
          'customfield_10333' => 'complex custom name',
          'customfield_10444' => 'duplicated custom name',
          'customfield_10666' => 'duplicate of a system name',
        })
      }

      it "can find a standard field by id" do
        expect(subject.priority).to eq(1)
      end

      it "can find a custom field by customfield_##### name" do
        expect(subject.customfield_10111).to eq('data_in_custom_field')
      end

      it "is not confused by common attribute keys" do
        expect{subject.name}.to raise_error(NoMethodError)
        expect{subject.custom}.to raise_error(NoMethodError)
        expect(subject.id).to eq(nil)   # picks up ID from the parent -
      end
    end

    context "before fields are mapped" do

      include_context "mapped or not"

      it "can find a standard field by id" do
        expect(subject.priority).to eq(1)
      end

      it "cannot find a standard field by name before mapping" do
        expect{subject.Priority}.to raise_error(NoMethodError)
      end

      it "can find a custom field by customfield_##### name" do
        expect(subject.customfield_10111).to eq('data_in_custom_field')
      end

      it "cannot find a mapped field before mapping and raises error" do
        expect{subject.SingleWork}.to raise_error(NoMethodError)
      end

      it "is not confused by common attribute keys and raises error" do
        expect{subject.name}.to raise_error(NoMethodError)
        expect{subject.custom}.to raise_error(NoMethodError)
        expect(subject.id).to eq(nil)   # picks up ID from the parent -
      end
    end

    context "after fields are mapped" do

      before do
        silence_stream(STDERR) do
          expect(client.Field.map_fields.class).to eq(Hash)
        end
      end

      include_context "mapped or not"

      it "warns of duplicate fields" do
        expect{client.Field.map_fields}.to output(/renaming as Priority_10666/).to_stderr
        expect{client.Field.map_fields}.to output(/renaming as SingleWord_10444/).to_stderr
      end

      it "can find a mapped field after mapping and returns results" do
        expect{subject.SingleWord}.to_not raise_error
        expect(subject.SingleWord).to eq subject.customfield_10111
      end

      it "handles duplicate names in a safe fashion" do
        expect{subject.Multi_Word}.to_not raise_error
        expect(subject.Multi_Word).to eq subject.customfield_10222
      end

      it "handles special characters in a safe fashion" do
        expect{subject.Why_N_t}.to_not raise_error
        expect(subject.Why_N_t).to eq subject.customfield_10333
      end

      it "handles duplicates in custom names" do
        expect{subject.SingleWord_10444}.to_not raise_error
        expect(subject.SingleWord_10444).to eq subject.customfield_10444
      end

      it "keeps custom names from overwriting system names" do
        #expect(client.Field.map_fields.class).to eq(Hash)
        expect{subject.Priority_10666}.to_not raise_error
        expect(subject.Priority_10666).to eq subject.customfield_10666
      end

      it "can find a standard field by an expanded name" do
        #expect(client.Field.map_fields.class).to eq(Hash)
        expect(subject.priority).to eq(1)
        expect(subject.Priority).to eq(1)
      end
    end
  end
end
