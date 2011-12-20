module JIRA
  module Resource

    class ComponentFactory < BaseFactory ; end

    class Component < Base
    
      def self.key_attribute
        :id
      end

    end

  end
end
