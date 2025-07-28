require 'cgi'
require 'json'

module JIRA
  module Resource
    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base
      has_one :reporter,  class: JIRA::Resource::User,
                          nested_under: 'fields'
      has_one :assignee,  class: JIRA::Resource::User,
                          nested_under: 'fields'
      has_one :project,   nested_under: 'fields'

      has_one :issuetype, nested_under: 'fields'

      has_one :priority,  nested_under: 'fields'

      has_one :status,    nested_under: 'fields'

      has_many :transitions

      has_many :components, nested_under: 'fields'

      has_many :comments, nested_under: %w[fields comment]

      has_many :attachments, nested_under: 'fields',
                             attribute_key: 'attachment'

      has_many :versions,    nested_under: 'fields'
      has_many :fixVersions, class: JIRA::Resource::Version,
                             nested_under: 'fields'

      has_many :worklogs, nested_under: %w[fields worklog]
      has_one :sprint, class: JIRA::Resource::Sprint,
                       nested_under: 'fields'

      has_many :closed_sprints, class: JIRA::Resource::Sprint,
                                nested_under: 'fields', attribute_key: 'closedSprints'

      has_many :issuelinks, nested_under: 'fields'

      has_many :remotelink, class: JIRA::Resource::Remotelink

      def self.all(client)
        url = client.options[:rest_base_path_v3] + '/search/jql?expand=transitions.fields'
        response = client.get(url)
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def self.jql(client, jql, options = { fields: nil, start_at: nil, max_results: nil, expand: nil })
        url = client.options[:rest_base_path_v3] + '/search/jql?jql=' + CGI.escape(jql)

        if options[:fields]
          url << "&fields=#{options[:fields].map do |value|
            CGI.escape(client.Field.name_to_id(value))
          end.join(',')}"
        end
        url << "&startAt=#{CGI.escape(options[:start_at].to_s)}" if options[:start_at]
        url << "&maxResults=#{CGI.escape(options[:max_results].to_s)}" if options[:max_results]

        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          url << "&expand=#{options[:expand].to_a.map { |value| CGI.escape(value.to_s) }.join(',')}"
        end

        response = client.get(url)
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def editmeta
        editmeta_url = client.options[:rest_base_path] + "/#{self.class.endpoint_name}/#{key}/editmeta"

        response = client.get(editmeta_url)
        json = self.class.parse_json(response.body)
        json['fields']
      end

      def respond_to?(method_name, include_all = false)
        if attrs.keys.include?('fields') && [method_name.to_s, client.Field.name_to_id(method_name)].any? do |k|
          attrs['fields'].key?(k)
        end
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include?('fields')
          if attrs['fields'].keys.include?(method_name.to_s)
            attrs['fields'][method_name.to_s]
          else
            official_name = client.Field.name_to_id(method_name)
            if attrs['fields'].keys.include?(official_name)
              attrs['fields'][official_name]
            else
              super(method_name, *args, &block)
            end
          end
        else
          super(method_name, *args, &block)
        end
      end
    end
  end
end
