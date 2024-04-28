# frozen_string_literal: true

module JIRA
  module Resource
    class IssuePickerSuggestionsFactory < JIRA::BaseFactory # :nodoc:
    end

    class IssuePickerSuggestions < JIRA::Base
      has_many :sections, class: JIRA::Resource::IssuePickerSuggestionsIssue

      def self.all(client, query = '', options = { current_jql: nil, current_issue_key: nil, current_project_id: nil, show_sub_tasks: nil, show_sub_tasks_parent: nil })
        url = client.options[:rest_base_path] + "/issue/picker?query=#{CGI.escape(query)}"

        url << "&currentJQL=#{CGI.escape(options[:current_jql])}" if options[:current_jql]
        url << "&currentIssueKey=#{CGI.escape(options[:current_issue_key])}" if options[:current_issue_key]
        url << "&currentProjectId=#{CGI.escape(options[:current_project_id])}" if options[:current_project_id]
        url << "&showSubTasks=#{options[:show_sub_tasks]}" if options[:show_sub_tasks]
        url << "&showSubTaskParent=#{options[:show_sub_task_parent]}" if options[:show_sub_task_parent]

        response = client.get(url)
        json = parse_json(response.body)
        client.IssuePickerSuggestions.build(json)
      end
    end
  end
end
