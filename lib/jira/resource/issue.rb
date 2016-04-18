require 'cgi'

module JIRA
  module Resource

    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base

      has_one :reporter,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :assignee,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :project,   :nested_under => 'fields'

      has_one :issuetype, :nested_under => 'fields'

      has_one :priority,  :nested_under => 'fields'

      has_one :status,    :nested_under => 'fields'

      has_many :transitions

      has_many :components, :nested_under => 'fields'

      has_many :comments, :nested_under => ['fields','comment']

      has_many :attachments, :nested_under => 'fields',
                          :attribute_key => 'attachment'

      has_many :versions,    :nested_under => 'fields'
      has_many :fixVersions, :class => JIRA::Resource::Version,
                             :nested_under => 'fields'

      has_many :worklogs, :nested_under => ['fields','worklog']

      has_many :issuelinks, :nested_under => 'fields'

      has_many :remotelink, :class => JIRA::Resource::Remotelink

      def self.all(client,  options = {fields: nil, startAt: nil, maxResults: nil, expand: nil})
        url = client.options[:rest_base_path] + "/search?expand=transitions.fields"
        url = url_with_query_params(url, options)
        response = client.get(url)
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def self.jql(client, jql, options = {fields: nil, startAt: nil, maxResults: nil, expand: nil})
        url = client.options[:rest_base_path] + "/search?jql=" + CGI.escape(jql)

        url << "&fields=#{options[:fields].map{ |value| CGI.escape(value.to_s) }.join(',')}" if options[:fields]
        url << "&startAt=#{CGI.escape(options[:startAt].to_s)}" if options[:start_at]
        url << "&maxResults=#{CGI.escape(options[:maxResults].to_s)}" if options[:maxResults]

        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          url << "&expand=#{options[:expand].to_a.map{ |value| CGI.escape(value.to_s) }.join(',')}"
        end

        response = client.get(url)
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def respond_to?(method_name, include_all=false)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          attrs['fields'][method_name.to_s]
        else
          super(method_name)
        end
      end

    end

  end
end
