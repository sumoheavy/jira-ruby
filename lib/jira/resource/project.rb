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
      def issues(options={})
        search_url = client.options[:rest_base_path] + '/search'
        query_params = {:jql => "project=\"#{key}\""}
        query_params.update Base.query_params_for_search(options)
        response = client.get(url_with_query_params(search_url, query_params))
        json = self.class.parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def users(options={})
        users_url = client.options[:rest_base_path] + '/user/assignable/search'
        query_params = { project: self.key_value }
        query_params['startAt'] = options[:start_at] if options[:start_at]
        query_params['maxResults'] = options[:max_results] if options[:max_results]
        response = client.get(url_with_query_params(users_url, query_params))
        json = self.class.parse_json(response.body)
        json.map do |jira_user|
          client.User.build(jira_user)
        end
      end
    end
  end
end
