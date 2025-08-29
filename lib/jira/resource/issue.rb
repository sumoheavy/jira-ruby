# frozen_string_literal: true

require 'cgi'
require 'json'

module JIRA
  module Resource
    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    # This class provides the Issue object <-> REST mapping for JIRA::Resource::Issue derived class,
    # i.e. the Create, Retrieve, Update, Delete lifecycle methods.
    #
    # == Lifecycle methods
    #
    # === Retrieving all issues
    #
    #   client.Issue.all
    #
    # === Retrieving a single issue
    #
    #   options = { expand: 'editmeta' }
    #   issue = client.Issue.find("SUP-3000", options)
    #
    # === Creating a new issue
    #
    #   issue = client.Issue.build(fields: { summary: 'New issue', project: { key: 'SUP' }, issuetype: { name: 'Bug' } })
    #   issue.save
    #
    # === Updating an issue
    #
    #   issue = client.Issue.find("SUP-3000")
    #   issue.save(fields: { summary: 'Updated issue' })
    #
    # === Deleting an issue
    #
    #   issue = client.Issue.find("SUP-3000")
    #   issue.delete
    #
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

      # Get collection of issues.
      # @param client [JIRA::Client]
      # @return [Array<JIRA::Resource::Issue>]
      def self.all(client)
        start_at = 0
        max_results = 1000
        result = []
        loop do
          url = client.options[:rest_base_path] +
                "/search/jql?expand=transitions.fields&maxResults=#{max_results}&startAt=#{start_at}"
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

      def self.jql(client, jql, options = { fields: nil, max_results: nil, expand: nil, reconcile_issues: nil })
        url = client.options[:rest_base_path] + "/search/jql?jql=#{CGI.escape(jql)}"

        if options[:fields]
          url << "&fields=#{options[:fields].map do |value|
                              CGI.escape(client.Field.name_to_id(value))
                            end.join(',')}"
        end
        url << "&maxResults=#{CGI.escape(options[:max_results].to_s)}" if options[:max_results]
        url << "&reconcileIssues=#{CGI.escape(options[:reconcile_issues].to_s)}" if options[:reconcile_issues]

        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          url << "&expand=#{options[:expand].to_a.map { |value| CGI.escape(value.to_s) }.join(',')}"
        end

        issues = []
        next_page_token = nil
        json = {}
        while json['isLast'] != true
          page_url = url.dup
          page_url << "&nextPageToken=#{next_page_token}" if next_page_token

          response = client.get(page_url)
          json = parse_json(response.body)
          return json['total'] if options[:max_results]&.zero?
          next_page_token = json['nextPageToken']
          json['issues'].map do |issue|
            issues << client.Issue.build(issue)
          end
        end
        issues
      end

      # Fetches the attributes for the specified resource from JIRA unless
      # the resource is already expanded and the optional force reload flag
      # is not set
      # @param [Boolean] reload
      # @param [Hash] query_params
      # @option query_params [String] :fields
      # @option query_params [String] :expand
      # @option query_params [Integer] :startAt
      # @option query_params [Integer] :maxResults
      # @return [void]
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

      # @private
      def respond_to?(method_name, _include_all = false)
        if attrs.key?('fields') && [method_name.to_s, client.Field.name_to_id(method_name)].any? do |k|
             attrs['fields'].key?(k)
           end
          true
        else
          super(method_name)
        end
      end

      # @private
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

      # @!method self.find(client, key, options = {})
      #   Gets/fetches an issue from JIRA.
      #
      #   Note: attachments are not fetched by default.
      #
      #   @param [JIRA::Client] client
      #   @param [String] key the key of the issue to find
      #   @param [Hash] options the options to find the issue with
      #   @option options [String] :fields the fields to include in the response
      #   @return [JIRA::Resource::Issue] the found issue
      #   @example Find an issue
      #   JIRA::Resource::Issue.find(client, "SUP-3000", { fields: %w[summary description attachment created ] } )
      #
      # @!method self.build(attrs = {})
      #   Constructs a new issue object.
      #   @param [Hash] attrs the attributes to initialize the issue with
      #   @return [JIRA::Resource::Issue] the new issue
      #
      # .
    end
  end
end
