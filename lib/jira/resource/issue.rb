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

      def self.all(client)
        url = client.options[:rest_base_path] + "/search?expand=transitions.fields"
        response = client.get(url)
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def self.jql(client, jql, options = {fields: nil, start_at: nil, max_results: nil, expand: nil})
        url = client.options[:rest_base_path] + "/search?jql=" + CGI.escape(jql)

        url << "&fields=#{options[:fields].map{ |value| CGI.escape(client.Field.name_to_id(value)) }.join(',')}" if options[:fields]
        url << "&startAt=#{CGI.escape(options[:start_at].to_s)}" if options[:start_at]
        url << "&maxResults=#{CGI.escape(options[:max_results].to_s)}" if options[:max_results]

        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          url << "&expand=#{options[:expand].to_a.map{ |value| CGI.escape(value.to_s) }.join(',')}"
        end

        response = client.get(url)
        json = parse_json(response.body)
        if options[:max_results] and options[:max_results] == 0
          return json['total']
        end
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
        if @attrs and @attrs['fields'] and @attrs['fields']['worklog'] and @attrs['fields']['worklog']['total'] > @attrs['fields']['worklog']['maxResults']
          worklog_url = client.options[:rest_base_path] + "/#{self.class.endpoint_name}/#{id}/worklog"
          response = client.get(worklog_url)
          unless response.body.nil? or response.body.length < 2
            set_attrs({'fields' => { 'worklog' => self.class.parse_json(response.body) }}, false)
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

      def respond_to?(method_name, include_all=false)
        if attrs.keys.include?('fields') && [method_name.to_s, client.Field.name_to_id(method_name)].any? {|k| attrs['fields'].key?(k)}
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
            official_name=client.Field.name_to_id(method_name)
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
