module JIRA
  module Resource

    class ProjectFactory < BaseFactory ; end

    class Project < Base

      has_one :lead, :class => JIRA::Resource::User
      has_many :components
      has_many :issuetypes, :attribute_key => 'issueTypes'

      def self.key_attribute
        :key
      end

      # Returns all the issues for this project
      def issues
        response = client.get(client.options[:rest_base_path] + "/search?jql=project%3D'#{key}'")
        json = self.class.parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

    end

  end
end
