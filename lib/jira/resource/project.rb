module JIRA
  module Resource

    class ProjectFactory < JIRA::BaseFactory # :nodoc:
    end

    class Project < JIRA::Base

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
      
      def versions
        path = "#{self.class.singular_path(client, key)}/versions"
        response = client.get path
        vs = self.class.parse_json(response.body)
        vs.map! do |v|
          client.Version.build v
        end
        vs
      end

    end

  end
end
