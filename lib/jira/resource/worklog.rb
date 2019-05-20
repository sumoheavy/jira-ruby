module JIRA
  module Resource
    class WorklogFactory < JIRA::BaseFactory # :nodoc:
    end

    class Worklog < JIRA::Base
      has_one :author, class: JIRA::Resource::User
      has_one :update_author, class: JIRA::Resource::User,
                              attribute_key: 'updateAuthor'
      belongs_to :issue
      nested_collections true

      def self.endpoint_name
        'worklog'
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        path = "#{issue.self}/#{endpoint_name}"
        response = client.get(path)
        json = parse_json(response.body)
        json['worklogs'].map do |worklog|
          issue.worklogs.build(worklog)
        end
      end
    end
  end
end
