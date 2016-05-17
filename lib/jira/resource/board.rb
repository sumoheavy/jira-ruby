require 'cgi'

module JIRA
  module Resource

    class BoardFactory < JIRA::BaseFactory # :nodoc:
    end

    class Board < JIRA::Base

      def self.all(client)
        response = client.get(path_base(client) + '/board')
        json = parse_json(response.body)
        json['values'].map do |board|
          client.Board.build(board)
        end
      end

      def self.find(client, key, options = {})
        response = client.get(path_base(client) + "/board/#{key}")
        json = parse_json(response.body)
        client.Board.build(json)
      end

      def issues(options = {})
        response = client.get(path_base(client) + "/board/#{id}/issue?#{options.to_query}")
        json = self.class.parse_json(response.body)
        json['issues'].map { |issue| client.Issue.build(issue) }
      end

      # options
      #   - state ~ future, active, closed, you can define multiple states separated by commas, e.g. state=active,closed
      #   - maxResults ~ default: 50
      #   - startAt ~ base index, starts at 0
      def sprints(options = {})
        response = client.get(path_base(client) + "/board/#{id}/sprint?#{options.to_query}")
        json = self.class.parse_json(response.body)
        json['values'].map do |sprint|
          sprint['rapidview_id'] = id
          client.Sprint.build(sprint)
        end
      end

      def project
        response = client.get(path_base(client) + "/board/#{id}/project")
        json = self.class.parse_json(response.body)
        json['values'][0]
      end

      def add_issue_to_backlog(issue)
        client.post(path_base(client) + '/backlog', {issues: [issue.id]}.to_json)
      end

      private

      def self.path_base(client)
        client.options[:context_path] + '/rest/agile/1.0'
      end

      def path_base(client)
        self.class.path_base(client)
      end

    end

  end
end
