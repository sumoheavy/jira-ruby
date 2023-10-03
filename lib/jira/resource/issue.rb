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
      has_many :worklogs
      has_many :changelogs

      has_many :components, nested_under: 'fields'

      has_many :comments, nested_under: %w[fields comment]

      has_many :attachments, nested_under: 'fields',
                             attribute_key: 'attachment'

      has_many :versions,    nested_under: 'fields'
      has_many :fixVersions, class: JIRA::Resource::Version,
                             nested_under: 'fields'


      has_one :sprint, class: JIRA::Resource::Sprint,
                       nested_under: 'fields'

      has_many :closed_sprints, class: JIRA::Resource::Sprint,
                                nested_under: 'fields', attribute_key: 'closedSprints'

      has_many :issuelinks, nested_under: 'fields'

      has_many :remotelink, class: JIRA::Resource::Remotelink

      has_many :watchers,   attribute_key: 'watches',
                            nested_under: %w[fields watches]

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

      def self.jql(client, jql, options = { fields: nil, start_at: nil, max_results: nil, expand: nil, validate_query: true, autopaginate: true })
        search_url = client.options[:rest_base_path] + '/search'
        query_params = { jql: jql }
        query_params.update(fields: options[:fields].map { |value| client.Field.name_to_id(value) }.join(',')) if options[:fields]
        query_params.update(startAt: options[:start_at].to_s) if options[:start_at]
        query_params.update(maxResults: options[:max_results].to_s) if options[:max_results]
        query_params.update(validateQuery: 'false') if options[:validate_query] === false
        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          query_params.update(expand: options[:expand].to_a.join(','))
        end

        response = client.get(url_with_query_params(search_url, query_params))

        json = parse_json(response.body)
        if options[:max_results] && (options[:max_results] == 0)
          return json['total']
        end

        result_issues = json['issues']

        autopaginate = options[:autopaginate]
        if autopaginate
          while (json['startAt'] + json['maxResults']) < json['total']
            query_params['startAt'] = (json['startAt'] + json['maxResults'])
            response = client.get(url_with_query_params(search_url, query_params))
            json = parse_json(response.body)
            result_issues += json['issues']
          end
        end

        result_issues.map do |issue|
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
        if @attrs && @attrs['fields'] && @attrs['fields']['worklog'] && (@attrs['fields']['worklog']['total'] > @attrs['fields']['worklog']['maxResults'])
          worklog_url = client.options[:rest_base_path] + "/#{self.class.endpoint_name}/#{id}/worklog"
          response = client.get(worklog_url)
          unless response.body.nil? || (response.body.length < 2)
            set_attrs({ 'fields' => { 'worklog' => self.class.parse_json(response.body) } }, false)
          end
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
        if attrs.key?('fields') && [method_name.to_s, client.Field.name_to_id(method_name)].any? { |k| attrs['fields'].key?(k) }
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.key?('fields')
          if attrs['fields'].key?(method_name.to_s)
            attrs['fields'][method_name.to_s]
          else
            official_name = client.Field.name_to_id(method_name)
            if attrs['fields'].key?(official_name)
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
