require 'spec_helper'

describe JIRA::Resource::IssueCount do

  class JIRAResourceDelegation < SimpleDelegator # :nodoc:
  end

  let(:client) { double(options: {rest_base_path: '/jira/rest/api/2'}) }


  it "should find all issues" do
    response = double()

    expect(client).to receive(:get).with('/jira/rest/api/2/search?expand=transitions.fields&maxResults=0').
      and_return(response)
  end


  it "should search an issue with a jql query string" do
    response = double()

    expect(client).to receive(:get).with('/jira/rest/api/2/search?jql=foo+bar&maxResults=0').
      and_return(response)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::IssueCount.jql(client,'foo bar')).to eq([''])
  end

  it "should search an issue with a jql query string and fields" do
    response = double()

    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&fields=foo,bar&maxResults=0')
      .and_return(response)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::IssueCount.jql(client, 'foo bar', fields: ['foo','bar'])).to eq([''])
  end

  it "should search an issue with a jql query string, start at" do
    response = double()

    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&startAt=1&maxResults=0')
      .and_return(response)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::IssueCount.jql(client,'foo bar', start_at: 1)).to eq([''])
  end

  it "should search an issue with a jql query string and string expand" do
    response = double()

    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&expand=transitions&maxResults=0')
      .and_return(response)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::IssueCount.jql(client,'foo bar', expand: 'transitions')).to eq([''])
  end

  it "should search an issue with a jql query string and array expand" do
    response = double()

    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&expand=transitions&maxResults=0')
      .and_return(response)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::IssueCount.jql(client,'foo bar', expand: %w(transitions))).to eq([''])
  end

end
