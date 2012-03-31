module JIRA
  module Resource

    class ProjectFactory < JIRA::BaseFactory # :nodoc:
    end

    class Project < JIRA::Base

      has_one :lead, :class => JIRA::Resource::User
      has_many :components
      has_many :issuetypes, :attribute_key => 'issueTypes'
      has_many :versions

      def self.key_attribute
        :key
      end

      # Returns all the issues for this project
      def issues(jql = nil)
       
        issues = []
        fetched_results = 0
        begin
          uri = client.options[:rest_base_path] + "/search?startAt=#{fetched_results}"
          uri << "&jql=project%3D'#{key}'"
          uri << URI.escape(" and #{jql}") if jql

          response = client.get(uri)
          json = self.class.parse_json(response.body)
          
          issues = issues + json['issues'].map do |issue|
            client.Issue.build(issue)
          end

          fetched_results += json['maxResults']

        end while fetched_results < json['total']

        issues
        
      end

    end

  end
end
