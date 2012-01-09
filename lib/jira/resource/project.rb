module JIRA
  module Resource

    class ProjectFactory < BaseFactory ; end

    class Project < Base ; end

      def self.key_attribute
        :key
      end

  end
end
