module JIRA
  module Resource

    class IssueFactory < BaseFactory ; end

    class Issue < Base

      def self.all(client)
        response = client.get(client.options[:rest_base_path] + "/search")
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

    end

  end
end
