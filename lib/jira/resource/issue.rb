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

      has_many :components, :nested_under => 'fields'

      has_many :comments, :nested_under => ['fields','comment']

      has_many :attachments, :nested_under => 'fields',
                          :attribute_key => 'attachment'

      has_many :versions, :nested_under => 'fields'

      has_many :worklogs, :nested_under => ['fields','worklog']

      def self.all(client)
        response = client.get(client.options[:rest_base_path] + "/search")
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def changelogs
        change_histories = []

        url = client.options[:rest_base_path] + "/issue/#{id}?expand=changelog&fields=summary"
        response = client.get(url)
        json = self.class.parse_json(response.body)
        change_histories = json['changelog']['histories'].map do |h|
          client.Changelog.build(h)
        end
        change_histories

      end

      def respond_to?(method_name)
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
