module JIRA
  module Resource

    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base

      extend JIRA::Mixins::Searchable

      expand_field :changelog

      has_one :reporter,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :assignee,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :project,   :nested_under => 'fields'

      has_one :issuetype, :nested_under => 'fields'

      has_one :priority,  :nested_under => 'fields'

      has_one :status,    :nested_under => 'fields'

      has_many :components, :nested_under => 'fields'

      has_many :labels, :nested_under => 'fields',
                          :class => String

      has_many :comments, :nested_under => ['fields','comment']

      has_many :attachments, :nested_under => 'fields',
                          :attribute_key => 'attachment'

      has_many :versions, :nested_under => 'fields'

      has_many :worklogs , :nested_under => ['fields','worklog']

      has_many :changelog, :nested_under => ['changelog'], :attribute_key => 'histories'

      def self.all(client, jql = nil,&block)
        Log.warn "Blockgiven #{block_given?}"
        page_jql(client,jql, &block )
      end

      def respond_to?(method_name)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          attrs['fields'][method_name.to_s]
        else
          super(method_name)
        end
      end

    end

  end
end
