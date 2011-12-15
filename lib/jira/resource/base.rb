module Jira
  module Resource

    class Base

      attr_reader :client
      attr_accessor :expanded, :deleted, :attrs
      alias :expanded? :expanded
      alias :deleted? :deleted

      def initialize(client, options = {})
        @client   = client
        @attrs    = options[:attrs] || {}
        @expanded = options[:expanded] || false
        @deleted  = false
      end

      # The class methods are never called directly, they are always
      # invoked from a BaseFactory subclass instance.
      def self.all(client)
        response = client.get(rest_base_path(client))
        json = parse_json(response.body)
        json.map do |attrs|
          self.new(client, :attrs => attrs)
        end
      end

      def self.find(client, key)
        instance = self.new(client)
        instance.attrs[key_attribute.to_s] = key
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

      def self.key_attribute
        :key
      end

      def self.parse_json(string)
        JSON.parse(string)
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
        set_attrs_from_response(response)
        @expanded = true
      end

      def save
        http_method = new_record? ? :post : :put
        response = client.send(http_method, url, to_json)
        set_attrs_from_response(response)
        @expanded = false
        true
      end

      def set_attrs_from_response(response)
        unless response.body.nil? or response.body.length < 2
          json = self.class.parse_json(response.body)
          @attrs.merge!(json)
          json
        end
      end

      def delete
        client.delete(url)
        @deleted = true
      end

      def url
        if @attrs['self']
          @attrs['self']
        elsif @attrs[self.class.key_attribute.to_s]
          rest_base_path + "/" + @attrs[self.class.key_attribute.to_s].to_s
        else
          rest_base_path
        end
      end

      def to_s
        "#<#{self.class.name}:#{object_id} @attrs=#{@attrs.inspect}>"
      end

      def to_json
        attrs.to_json
      end

      def new_record?
        @attrs['id'].nil?
      end
    end

  end
end
