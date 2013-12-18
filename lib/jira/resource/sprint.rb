module JIRA
  module Resource

    class SprintFactory < JIRA::BaseFactory # :nodoc:
    end
=begin
    class Sprint < JIRA::Base

      has_many :completed_issues,   :nested_under => 'contents'
      has_many :incompleted_issues, :nested_under => 'contents'
      has_many :punted_issues,      :nested_under => 'contents'

      def self.find(client, rapid_view_id, sprint_id, options = {})
        instance = self.new(client, options)
        instance.attrs[]
        instance.fetch
        instance 
      end
    end
=end
  end
end