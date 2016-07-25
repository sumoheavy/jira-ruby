require "spec_helper"

describe JIRA::Resource::Sprint do
  describe "peristence" do
    let(:sprint) { described_class.new(client) }
    let(:client) { double("Client", options: { site: "https://foo.bar.com" }) }

    describe "#save" do
      let(:agile_sprint_url) { "#{sprint.client.options[:site]}/rest/agile/1.0/sprint/#{sprint.id}" }
      let(:instance_attrs) { { start_date: "2016-06-01" } }

      before do
        sprint.attrs = instance_attrs
      end

      context "when attributes are specified" do
        let(:given_attrs) { { start_date: "2016-06-10" } }

        it "calls save on the super class with the given attributes & agile url" do
          expect_any_instance_of(JIRA::Base).
            to receive(:save).with(given_attrs, agile_sprint_url).and_return(true)

          sprint.save(given_attrs)
        end
      end

      context "when attributes are not specified" do
        it "calls save on the super class with the instance attributes & agile url" do
          expect_any_instance_of(JIRA::Base).
            to receive(:save).with(instance_attrs, agile_sprint_url).and_return(true)

          sprint.save
        end
      end
    end

    describe "#save!" do
      let(:agile_sprint_url) { "#{sprint.client.options[:site]}/rest/agile/1.0/sprint/#{sprint.id}" }
      let(:instance_attrs) { { start_date: "2016-06-01" } }

      before do
        sprint.attrs = instance_attrs
      end

      context "when attributes are specified" do
        let(:given_attrs) { { start_date: "2016-06-10" } }

        it "calls save! on the super class with the given attributes & agile url" do
          expect_any_instance_of(JIRA::Base).
            to receive(:save!).with(given_attrs, agile_sprint_url).and_return(true)

          sprint.save!(given_attrs)
        end
      end

      context "when attributes are not specified" do
        it "calls save! on the super class with the instance attributes & agile url" do
          expect_any_instance_of(JIRA::Base).
            to receive(:save!).with(instance_attrs, agile_sprint_url).and_return(true)

          sprint.save!
        end
      end
    end
  end
end
