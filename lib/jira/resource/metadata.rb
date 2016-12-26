module JIRA
  module Resource
    class Metadata
      
      def initialize(project_id, raw_issuetypes)
        @project_id       = project_id
        @raw_issuetypes   = raw_issuetypes
        @issuetypes =  @raw_issuetypes.map do |raw_issuetype|
          raw_issuetype.tap { |issuetype| issuetype["key"] = issuetype["name"].downcase }
        end
      end

    end
  end
end