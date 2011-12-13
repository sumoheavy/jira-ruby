module Jira
  module Resource

    class Base

      attr_reader :client, :attrs
      attr_accessor :expanded
      alias :expanded? :expanded

      def initialize(client, options = {})
        @client   = client
        @attrs    = options[:attrs] || {}
        @expanded = options[:expanded] || false
      end

      # The class methods are never called directly, they are always
      # invoked from a BaseFactory subclass instance.
      def self.all(client)
        response = client.get(rest_base_path(client))
        json = JSON.parse(response.body)
        json.map do |attrs|
          self.new(client, :attrs => attrs)
        end
      end

      def self.find(client, key)
        instance = self.new(client)
        instance.attrs['key'] = key
        instance.fetch
        instance
      end

      def self.build(client, attrs)
        self.new(client, :attrs => attrs)
      end

      def self.rest_base_path(client)
        client.options[:rest_base_path] + '/' + self.endpoint_name
      end

      def self.endpoint_name
        self.name.split('::').last.downcase
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

      def fetch(reload = false)
        return if expanded? && !reload
        response = client.get(url)
        json = JSON.parse(response.body)
        @attrs = json
        @expanded = true
      end

      def url
        if @attrs['self']
          @attrs['self']
        elsif @attrs['key']
          rest_base_path + "/" + @attrs['key']
        else
          rest_base_path
        end
      end

    end

  end
end
