module JiraRuby
  module Resource

    class ProjectFactory

      attr_reader :client

      def initialize(client)
        @client = client
      end

      def all
        Project.all(@client)
      end

      def find(key)
        Project.find(@client, key)
      end
    end

    class Project

      attr_reader :client, :attrs

      def initialize(client, attrs)
        @client = client
        @attrs  = attrs
      end

      # The class methods are never called directly, they are always
      # invoked from a ProjectFactory instance.
      def self.all(client)
        response = client.get(rest_base_path(client))
        json = JSON.parse(response.body)
        json.map do |attrs|
          JiraRuby::Resource::Project.new(client, attrs)
        end
      end

      def self.find(client, key)
        response = client.get(rest_base_path(client) + "/" + key)
        json = JSON.parse(response.body)
        self.new(client, json)
      end

      def self.rest_base_path(client)
        client.options[:rest_base_path] + '/project'
      end


      def respond_to?(method_name)
        if attrs.keys.include? method_name.to_s
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include? method_name.to_s
          attrs[method_name.to_s]
        else
          super(method_name)
        end
      end

      def rest_base_path
        # Just proxy this to the class method
        self.class.rest_base_path(client)
      end

    end
  end
end
