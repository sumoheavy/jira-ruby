require_relative "metadata"

module JIRA
  module Resource

    class ProjectFactory < JIRA::BaseFactory # :nodoc:
    end

    class Project < JIRA::Base

      has_one :lead, :class => JIRA::Resource::User
      has_many :components
      has_many :issuetypes, :attribute_key => 'issueTypes'
      has_many :status, :attribute_key => 'statuses'
      has_many :versions

      def self.key_attribute
        :key
      end

      # Returns all the issues for this project
      def issues(options={})
        options = options.with_indifferent_access
        search_url = client.options[:rest_base_path] + '/search'
        query_params = { jql: "project=\"#{key}\"" }
        query_params.update Base.query_params_for_search(options)
        response = client.get(url_with_query_params(search_url, query_params))
        json = self.class.parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end
      
      def metadata
        @metadata ||= createmeta
      end

      def createmeta(options={})
        createmeta_url = client.options[:rest_base_path] + '/issue/createmeta/'
        query_params = {
          :projectKeys => self.key_value,
          # :issuetypeNames => ["Story", "Epic"],
          :expand => "projects.issuetypes.fields"
        }
        query_encoded = url_with_query_params(createmeta_url, query_params)
        response = client.get(query_encoded)
        
        json = self.class.parse_json(response.body)
        custom_fields = ['Story Points', 'Epic Link', 'Sprint', 'Epic Name']
        
        meta_data = {}

        issuetypes = json['projects'][0].try(:[],'issuetypes') || []
        
        struct = Metadata.new(self.key, issuetypes)
        
        issuetypes.each do |issuetype|
          fields = issuetype.fetch('fields')
          fields.each do |field|
            if custom_fields.include? field[1]['name']
              label = "#{issuetype['name']} #{field[1]['name']}".downcase.parameterize
              meta_data[label] = field[0]
            end
          end
        end
        metadata_struct = OpenStruct.new meta_data
        metadata_struct.project_id = self.key
        metadata_struct
      end

      def users
        users_url = client.options[:rest_base_path] + '/user/assignable/search'
        query_params = {:project => self.key_value}
        response = client.get(url_with_query_params(users_url, query_params))
        json = self.class.parse_json(response.body)
        json.map do |jira_user|
          client.User.build(jira_user)
        end
      end
    end
  end
end
