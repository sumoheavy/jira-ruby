# frozen_string_literal: true

require 'cgi'
require 'json'

module JIRA
  module Resource
    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base
      has_one :reporter, class: JIRA::Resource::User, nested_under: 'fields'
      has_one :assignee, class: JIRA::Resource::User, nested_under: 'fields'
      has_one :project, nested_under: 'fields'
      has_one :issuetype, nested_under: 'fields'
      has_one :priority, nested_under: 'fields'
      has_one :status, nested_under: 'fields'
      has_one :resolution, nested_under: 'fields'
      has_many :transitions
      has_many :components, nested_under: 'fields'
      has_many :comments, nested_under: %w[fields comment]
      has_many :attachments, nested_under: 'fields', attribute_key: 'attachment'
      has_many :versions, nested_under: 'fields'
      has_many :fixVersions, class: JIRA::Resource::Version, nested_under: 'fields'
      has_many :worklogs, nested_under: %w[fields worklog]
      has_one :sprint, class: JIRA::Resource::Sprint, nested_under: 'fields'
      has_many :closed_sprints, class: JIRA::Resource::Sprint, nested_under: 'fields', attribute_key: 'closedSprints'
      has_many :issuelinks, nested_under: 'fields'
      has_many :remotelink, class: JIRA::Resource::Remotelink
      has_many :watchers, attribute_key: 'watches', nested_under: %w[fields watches]

      def self.all(client)
        start_at = 0
        max_results = 1000
        result = []
        loop do
          url = client.options[:rest_base_path] +
                "/search?expand=transitions.fields&maxResults=#{max_results}&startAt=#{start_at}"
          response = client.get(url)
          json = parse_json(response.body)
          json['issues'].map do |issue|
            result.push(client.Issue.build(issue))
          end
          break if json['issues'].empty?

          start_at += json['issues'].size
        end
        result
      end

      def self.jql(client, jql, options = { fields: nil, start_at: nil, max_results: nil, expand: nil,
validate_query: true })
        url = client.options[:rest_base_path] + "/search?jql=#{CGI.escape(jql)}"

        if options[:fields]
          url << "&fields=#{options[:fields].map do |value|
                              CGI.escape(client.Field.name_to_id(value))
                            end.join(',')}"
        end
        url << "&startAt=#{CGI.escape(options[:start_at].to_s)}" if options[:start_at]
        url << "&maxResults=#{CGI.escape(options[:max_results].to_s)}" if options[:max_results]
        url << '&validateQuery=false' if options[:validate_query] === false

        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          url << "&expand=#{options[:expand].to_a.map { |value| CGI.escape(value.to_s) }.join(',')}"
        end

        response = client.get(url)
        json = parse_json(response.body)
        return json['total'] if options[:max_results] && (options[:max_results]).zero?

        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      # Fetches the attributes for the specified resource from JIRA unless
      # the resource is already expanded and the optional force reload flag
      # is not set
      def fetch(reload = false, query_params = {})
        return if expanded? && !reload

        response = client.get(url_with_query_params(url, query_params))
        set_attrs_from_response(response)
        if @attrs && @attrs['fields'] &&
           @attrs['fields']['worklog'] &&
           (@attrs['fields']['worklog']['total'] > @attrs['fields']['worklog']['maxResults'])
          worklog_url = client.options[:rest_base_path] + "/#{self.class.endpoint_name}/#{id}/worklog"
          response = client.get(worklog_url)
          set_attrs({ 'fields' => { 'worklog' => self.class.parse_json(response.body) } }, false) unless response.body.nil? || (response.body.length < 2)
        end
        @expanded = true
      end

      def editmeta
        editmeta_url = client.options[:rest_base_path] + "/#{self.class.endpoint_name}/#{key}/editmeta"

        response = client.get(editmeta_url)
        json = self.class.parse_json(response.body)
        json['fields']
      end

      def respond_to?(method_name, _include_all = false)
        if attrs.key?('fields') && [method_name.to_s, client.Field.name_to_id(method_name)].any? do |k|
             attrs['fields'].key?(k)
           end
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &)
        if attrs.key?('fields')
          if attrs['fields'].key?(method_name.to_s)
            attrs['fields'][method_name.to_s]
          else
            official_name = client.Field.name_to_id(method_name)
            if attrs['fields'].key?(official_name)
              attrs['fields'][official_name]
            else
              super
            end
          end
        else
          super
        end
      end
    end
  end
end
