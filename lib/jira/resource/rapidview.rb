require 'cgi'

module JIRA
  module Resource

    class RapidViewFactory < JIRA::BaseFactory # :nodoc:
    end

    class RapidView < JIRA::Base

      def self.all(client)
        response = client.get(path_base(client) + '/rapidview')
        json = parse_json(response.body)
        json['views'].map do |view|
          client.RapidView.build(view)
        end
      end

      def self.find(client, key, options = {})
        response = client.get(path_base(client) + "/rapidview/#{key}")
        json = parse_json(response.body)
        client.RapidView.build(json)
      end

      def issues(options = {})
        response = client.get(path_base(client) + "/xboard/plan/backlog/data?rapidViewId=#{id}")
        json = self.class.parse_json(response.body)
        # To get Issue objects with the same structure as for Issue.all
        issue_ids = json['issues'].map { |issue| issue['id'] }

        # First we have to get all IDs of parent and sub tasks
        jql = "id IN(#{issue_ids.join(', ')})"
        parent_issues = client.Issue.jql(jql)
        subtask_ids = parent_issues.map { |t| t.subtasks.map { |sub| sub['id'] } }.flatten

        parent_and_sub_ids = issue_ids + subtask_ids
        jql = "id IN(#{parent_and_sub_ids.join(', ')})"
        jql += " and updated >= '#{options.delete(:updated)}'" if options[:updated]
        client.Issue.jql(jql)
      end

      def sprints(options = {})
        params  = { includeHistoricSprints: options.fetch(:include_historic, false),
                    includeFutureSprints:   options.fetch(:include_future, false) }
        response = client.get(path_base(client) + "/sprintquery/#{id}?#{params.to_query}")
        json = self.class.parse_json(response.body)
        json['sprints'].map do |sprint|
          sprint['rapidview_id'] = id
          client.Sprint.build(sprint)
        end

      end

      private

      def self.path_base(client)
        client.options[:context_path] + '/rest/greenhopper/1.0'
      end

      def path_base(client)
        self.class.path_base(client)
      end

    end

  end
end
