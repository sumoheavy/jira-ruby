module JIRA
  module Resource

    class ProjectFactory < JIRA::BaseFactory # :nodoc:
    end

    class Project < JIRA::Base
      
      extend JIRA::Mixins::Searchable

      has_one :lead, :class => JIRA::Resource::User
      has_many :components
      has_many :issuetypes, :attribute_key => 'issueTypes'
      has_many :versions

      def self.key_attribute
        :key
      end

      # Returns all the issues for this project
      def issues(jql = nil, &block)
        self.class.page_jql(client,self.class.get_scoped_jql(self, jql), &block)       
      end

    end

  end
end
