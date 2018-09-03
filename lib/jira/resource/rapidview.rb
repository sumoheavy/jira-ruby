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

      def self.find(client, key, _options = {})
        response = client.get(path_base(client) + "/rapidview/#{key}")
        json = parse_json(response.body)
        client.RapidView.build(json)
      end

      def issues
        response = client.get(path_base(client) + "/xboard/plan/backlog/data?rapidViewId=#{id}")
        json = self.class.parse_json(response.body)
        # To get Issue objects with the same structure as for Issue.all
        issue_ids = json['issues'].map { |issue| issue['id'] }
        client.Issue.jql("id IN(#{issue_ids.join(', ')})")
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
