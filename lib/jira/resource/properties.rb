module JIRA
  module Resource
    class PropertiesFactory < JIRA::BaseFactory # :nodoc:
    end

    class Properties < JIRA::Base
      belongs_to :issue

      def self.key_attribute
        'key'
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue
        issue_properties = issue.properties
        response = client.get("#{issue.url}/#{endpoint_name}")
        json = parse_json(response.body)
        json['keys'].each do |prop|
          response = client.get(prop['self'])
          property = parse_json(response.body)
          issue_properties.build(property)
        end
        issue_properties
      end

      def self.find(client, key, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue
        ## Determine if we already have this property (via all or previous find)
        response = client.get("#{issue.url}/#{endpoint_name}/#{key}")
        property = parse_json(response.body)
        issue.properties.build(property)
      end

      def initialize(client, options = {})
        super(client, options)
        ## Automatically convert attrs to a hash of just the resource key
        ## if it's just a String (this simplifies the use case of build with just the key)
        @attrs = {self.class.key_attribute => @attrs} if @attrs.is_a?(String)
        if @attrs[self.class.key_attribute].nil?
          raise ArgumentError, "Required option #{self.class.key_attribute.inspect} is required"
        end
      end

      ## force new_record? to false to always force :put (the only REST option for setting issue property)
      def new_record?
        false
      end

      ## Override save so we can default the attrs
      def save!(attrs = {}, _path = nil)
        attrs = {'value' => attrs} unless attrs.is_a?(Hash)
        ## Note: the .dup here prevents set_attrs from trying to re-insert the same value into itself
        super(attrs.empty? ? @attrs['value'].dup : attrs.key?('value') ? attrs['value'] : attrs, _path)
      end

      ## Note: save ultimately calls save!, so put the real logic in there
      def save(attrs = {}, _path = nil)
        super(attrs, _path)
      end
    end
  end
end
