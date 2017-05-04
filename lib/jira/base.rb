require 'active_support/core_ext/string'
require 'active_support/inflector'
require 'set'

module JIRA

  # This class provides the basic object <-> REST mapping for all JIRA::Resource subclasses,
  # i.e. the Create, Retrieve, Update, Delete lifecycle methods.
  #
  # == Lifecycle methods
  #
  # Note that not all lifecycle
  # methods are available for all resources, for example some resources cannot be updated
  # or deleted.
  #
  # === Retrieving all resources
  #
  #   client.Resource.all
  #
  # === Retrieving a single resource
  #
  #   client.Resource.find(id)
  #
  # === Creating a resource
  #
  #   resource = client.Resource.build({'name' => '')
  #   resource.save
  #
  # === Updating a resource
  #
  #   resource = client.Resource.find(id)
  #   resource.save('updated_attribute' => 'new value')
  #
  # === Deleting a resource
  #
  #   resource = client.Resource.find(id)
  #   resource.delete
  #
  # == Nested resources
  #
  # Some resources are not defined in the top level of the URL namespace
  # within the JIRA API, but are always nested under the context of another
  # resource.  For example, a JIRA::Resource::Comment always belongs to a
  # JIRA::Resource::Issue.
  #
  # These resources must be indexed and built from an instance of the class
  # they are nested under:
  #
  #   issue = client.Issue.find(id)
  #   comments = issue.comments
  #   new_comment = issue.comments.build
  #
  class Base
    QUERY_PARAMS_FOR_SINGLE_FETCH = Set.new [:expand, :fields]
    QUERY_PARAMS_FOR_SEARCH = Set.new [:expand, :fields, :startAt, :maxResults]

    # A reference to the JIRA::Client used to initialize this resource.
    attr_reader :client

    # Returns true if this instance has been fetched from the server
    attr_accessor :expanded

    # Returns true if this instance has been deleted from the server
    attr_accessor :deleted

    # The hash of attributes belonging to this instance.  An exact
    # representation of the JSON returned from the JIRA API
    attr_accessor :attrs

    alias :expanded? :expanded
    alias :deleted? :deleted

    def initialize(client, options = {})
      @client   = client
      @attrs    = options[:attrs] || {}
      @expanded = options[:expanded] || false
      @deleted  = false

      # If this class has any belongs_to relationships, a value for
      # each of them must be passed in to the initializer.
      self.class.belongs_to_relationships.each do |relation|
        if options[relation]
          instance_variable_set("@#{relation.to_s}", options[relation])
          instance_variable_set("@#{relation.to_s}_id", options[relation].key_value)
        elsif options["#{relation}_id".to_sym]
          instance_variable_set("@#{relation.to_s}_id", options["#{relation}_id".to_sym])
        else
          raise ArgumentError.new("Required option #{relation.inspect} missing") unless options[relation]
        end
      end
    end

    # The class methods are never called directly, they are always
    # invoked from a BaseFactory subclass instance.
    def self.all(client, options = {})
      response = client.get(collection_path(client))
      json = parse_json(response.body)
      if collection_attributes_are_nested
        json = json[endpoint_name.pluralize]
      end
      json.map do |attrs|
        self.new(client, {:attrs => attrs}.merge(options))
      end
    end

    # Finds and retrieves a resource with the given ID.
    def self.find(client, key, options = {})
      instance = self.new(client, options)
      instance.attrs[key_attribute.to_s] = key
      instance.fetch(false, query_params_for_single_fetch(options))
      instance
    end

    # Builds a new instance of the resource with the given attributes.
    # These attributes will be posted to the JIRA Api if save is called.
    def self.build(client, attrs)
      self.new(client, :attrs => attrs)
    end

    # Returns the name of this resource for use in URL components.
    # E.g.
    #   JIRA::Resource::Issue.endpoint_name
    #     # => issue
    def self.endpoint_name
      self.name.split('::').last.downcase
    end

    # Returns the full path for a collection of this resource.
    # E.g.
    #   JIRA::Resource::Issue.collection_path
    #     # => /jira/rest/api/2/issue
    def self.collection_path(client, prefix = '/')
      client.options[:rest_base_path] + prefix + self.endpoint_name
    end

    # Returns the singular path for the resource with the given key.
    # E.g.
    #   JIRA::Resource::Issue.singular_path('123')
    #     # => /jira/rest/api/2/issue/123
    #
    # If a prefix parameter is provided it will be injected between the base
    # path and the endpoint.
    # E.g.
    #   JIRA::Resource::Comment.singular_path('456','/issue/123/')
    #     # => /jira/rest/api/2/issue/123/comment/456
    def self.singular_path(client, key, prefix = '/')
      collection_path(client, prefix) + '/' + key
    end

    # Returns the attribute name of the attribute used for find.
    # Defaults to :id unless overridden.
    def self.key_attribute
      :id
    end

    def self.parse_json(string) # :nodoc:
      JSON.parse(string)
    end

    # Declares that this class contains a singular instance of another resource
    # within the JSON returned from the JIRA API.
    #
    #   class Example < JIRA::Base
    #     has_one :child
    #   end
    #
    #   example = client.Example.find(1)
    #   example.child # Returns a JIRA::Resource::Child
    #
    # The following options can be used to override the default behaviour of the
    # relationship:
    #
    # [:attribute_key]  The relationship will by default reference a JSON key on the
    #                   object with the same name as the relationship.
    #
    #                     has_one :child # => {"id":"123",{"child":{"id":"456"}}}
    #
    #                   Use this option if the key in the JSON is named differently.
    #
    #                     # Respond to resource.child, but return the value of resource.attrs['kid']
    #                     has_one :child, :attribute_key => 'kid' # => {"id":"123",{"kid":{"id":"456"}}}
    #
    # [:class]          The class of the child instance will be inferred from the name of the
    #                   relationship. E.g. <tt>has_one :child</tt> will return a <tt>JIRA::Resource::Child</tt>.
    #                   Use this option to override the inferred class.
    #
    #                     has_one :child, :class => JIRA::Resource::Kid
    # [:nested_under]   In some cases, the JSON return from JIRA is nested deeply for particular
    #                   relationships.  This option allows the nesting to be specified.
    #
    #                     # Specify a single depth of nesting.
    #                     has_one :child, :nested_under => 'foo'
    #                       # => Looks for {"foo":{"child":{}}}
    #                     # Specify deeply nested JSON
    #                     has_one :child, :nested_under => ['foo', 'bar', 'baz']
    #                       # => Looks for {"foo":{"bar":{"baz":{"child":{}}}}}
    def self.has_one(resource, options = {})
      attribute_key = options[:attribute_key] || resource.to_s
      child_class = options[:class] || ('JIRA::Resource::' + resource.to_s.classify).constantize
      define_method(resource) do
        attribute = maybe_nested_attribute(attribute_key, options[:nested_under])
        return nil unless attribute
        child_class.new(client, :attrs => attribute)
      end
    end

    # Declares that this class contains a collection of another resource
    # within the JSON returned from the JIRA API.
    #
    #   class Example < JIRA::Base
    #     has_many :children
    #   end
    #
    #   example = client.Example.find(1)
    #   example.children # Returns an instance of Jira::Resource::HasManyProxy,
    #                    # which behaves exactly like an array of
    #                    # Jira::Resource::Child
    #
    # The following options can be used to override the default behaviour of the
    # relationship:
    #
    # [:attribute_key]  The relationship will by default reference a JSON key on the
    #                   object with the same name as the relationship.
    #
    #                     has_many :children # => {"id":"123",{"children":[{"id":"456"},{"id":"789"}]}}
    #
    #                   Use this option if the key in the JSON is named differently.
    #
    #                     # Respond to resource.children, but return the value of resource.attrs['kids']
    #                     has_many :children, :attribute_key => 'kids' # => {"id":"123",{"kids":[{"id":"456"},{"id":"789"}]}}
    #
    # [:class]          The class of the child instance will be inferred from the name of the
    #                   relationship. E.g. <tt>has_many :children</tt> will return an instance
    #                   of <tt>JIRA::Resource::HasManyProxy</tt> containing the collection of
    #                   <tt>JIRA::Resource::Child</tt>.
    #                   Use this option to override the inferred class.
    #
    #                     has_many :children, :class => JIRA::Resource::Kid
    # [:nested_under]   In some cases, the JSON return from JIRA is nested deeply for particular
    #                   relationships.  This option allows the nesting to be specified.
    #
    #                     # Specify a single depth of nesting.
    #                     has_many :children, :nested_under => 'foo'
    #                       # => Looks for {"foo":{"children":{}}}
    #                     # Specify deeply nested JSON
    #                     has_many :children, :nested_under => ['foo', 'bar', 'baz']
    #                       # => Looks for {"foo":{"bar":{"baz":{"children":{}}}}}
    def self.has_many(collection, options = {})
      attribute_key = options[:attribute_key] || collection.to_s
      child_class = options[:class] || ('JIRA::Resource::' + collection.to_s.classify).constantize
      self_class_basename = self.name.split('::').last.downcase.to_sym
      define_method(collection) do
        child_class_options = {self_class_basename => self}
        attribute = maybe_nested_attribute(attribute_key, options[:nested_under]) || []
        collection = attribute.map do |child_attributes|
          child_class.new(client, child_class_options.merge(:attrs => child_attributes))
        end
        HasManyProxy.new(self, child_class, collection)
      end
    end

    def self.belongs_to_relationships
      @belongs_to_relationships ||= []
    end

    def self.belongs_to(resource)
      belongs_to_relationships.push(resource)
      attr_reader resource
      attr_reader "#{resource}_id"
    end

    def self.collection_attributes_are_nested
      @collection_attributes_are_nested ||= false
    end

    def self.nested_collections(value)
      @collection_attributes_are_nested = value
    end

    def id
      attrs['id']
    end

    # Returns a symbol for the given instance, for example
    # JIRA::Resource::Issue returns :issue
    def to_sym
      self.class.endpoint_name.to_sym
    end

    # Checks if method_name is set in the attributes hash
    # and returns true when found, otherwise proxies the
    # call to the superclass.
    def respond_to?(method_name, include_all=false)
      if attrs.keys.include? method_name.to_s
        true
      else
        super(method_name)
      end
    end

    # Overrides method_missing to check the attribute hash
    # for resources matching method_name and proxies the call
    # to the superclass if no match is found.
    def method_missing(method_name, *args, &block)
      if attrs.keys.include? method_name.to_s
        attrs[method_name.to_s]
      else
        super(method_name)
      end
    end

    # Each resource has a unique key attribute, this method returns the value
    # of that key for this instance.
    def key_value
      @attrs[self.class.key_attribute.to_s]
    end

    def collection_path(prefix = "/")
      # Just proxy this to the class method
      self.class.collection_path(client, prefix)
    end

    # This returns the URL path component that is specific to this instance,
    # for example for Issue id 123 it returns '/issue/123'.  For an unsaved
    # issue it returns '/issue'
    def path_component
      path_component = "/#{self.class.endpoint_name}"
      if key_value
        path_component += '/' + key_value
      end
      path_component
    end

    # Fetches the attributes for the specified resource from JIRA unless
    # the resource is already expanded and the optional force reload flag
    # is not set
    def fetch(reload = false, query_params = {})
      return if expanded? && !reload
      response = client.get(url_with_query_params(url, query_params))
      set_attrs_from_response(response)
      @expanded = true
    end

    # Saves the specified resource attributes by sending either a POST or PUT
    # request to JIRA, depending on resource.new_record?
    #
    # Accepts an attributes hash of the values to be saved.  Will throw a
    # JIRA::HTTPError if the request fails (response is not HTTP 2xx).
    def save!(attrs)
      http_method = new_record? ? :post : :put
      response = client.send(http_method, new_record? ? url : patched_url, attrs.to_json)
      set_attrs(attrs, false)
      set_attrs_from_response(response)
      @expanded = false
      true
    end

    # Saves the specified resource attributes by sending either a POST or PUT
    # request to JIRA, depending on resource.new_record?
    #
    # Accepts an attributes hash of the values to be saved. Will return false
    # if the request fails.
    def save(attrs)
      begin
        save_status = save!(attrs)
      rescue JIRA::HTTPError => exception
        begin
          set_attrs_from_response(exception.response) # Merge error status generated by JIRA REST API
        rescue JSON::ParserError => parse_exception
          set_attrs("exception" => {
                        "class" => exception.response.class.name,
                        "code" => exception.response.code,
                        "message" => exception.response.message
                    }
          )
        end
        # raise exception
        save_status = false
      end
      save_status
    end

    # Sets the attributes hash from a HTTPResponse object from JIRA if it is
    # not nil or is not a json response.
    def set_attrs_from_response(response)
      unless response.body.nil? or response.body.length < 2
        json = self.class.parse_json(response.body)
        set_attrs(json)
      end
    end

    # Set the current attributes from a hash.  If clobber is true, any existing
    # hash values will be clobbered by the new hash, otherwise the hash will
    # be deeply merged into attrs.  The target paramater is for internal use only
    # and should not be used.
    def set_attrs(hash, clobber=true, target = nil)
      target ||= @attrs
      if clobber
        target.merge!(hash)
        hash
      else
        hash.each do |k, v|
          if v.is_a?(Hash)
            set_attrs(v, clobber, target[k])
          else
            target[k] = v
          end
        end
      end
    end

    # Sends a delete request to the JIRA Api and sets the deleted instance
    # variable on the object to true.
    def delete
      client.delete(url)
      @deleted = true
    end

    def has_errors?
      respond_to?('errors')
    end

    def url
      prefix = '/'
      unless self.class.belongs_to_relationships.empty?
        prefix = self.class.belongs_to_relationships.inject(prefix) do |prefix_so_far, relationship|
          prefix_so_far.to_s + relationship.to_s + "/" + self.send("#{relationship.to_s}_id").to_s + '/'
        end
      end
      if @attrs['self']
        the_url = @attrs['self'].sub(@client.options[:site],'')
        the_url = "/#{the_url}" if (the_url =~ /^\//).nil?
        the_url
      elsif key_value
        self.class.singular_path(client, key_value.to_s, prefix)
      else
        self.class.collection_path(client, prefix)
      end
    end

    # This method fixes issue that there is no / prefix in url. It is happened when we call for instance
    # Looks like this issue is actual only in case if you use atlassian sdk your app path is not root (like /jira in example below)
    # issue.save() for existing resource.
    # As a result we got error 400 from JIRA API:
    # [07/Jun/2015:15:32:19 +0400] "PUT jira/rest/api/2/issue/10111 HTTP/1.1" 400 -
    # After applying this fix we have normal response:
    # [07/Jun/2015:15:17:18 +0400] "PUT /jira/rest/api/2/issue/10111 HTTP/1.1" 204 -
    def patched_url
      result = url
      return result if result.start_with?('/')
      "/#{result}"
    end

    def to_s
      "#<#{self.class.name}:#{object_id} @attrs=#{@attrs.inspect}>"
    end

    # Returns a JSON representation of the current attributes hash.
    def to_json(options = {})
      attrs.to_json(options)
    end

    # Determines if the resource is newly created by checking whether its
    # key_value is set. If it is nil, the record is new and the method
    # will return true.
    def new_record?
      key_value.nil?
    end

    protected

    # This allows conditional lookup of possibly nested attributes.  Example usage:
    #
    #   maybe_nested_attribute('foo')                 # => @attrs['foo']
    #   maybe_nested_attribute('foo', 'bar')          # => @attrs['bar']['foo']
    #   maybe_nested_attribute('foo', ['bar', 'baz']) # => @attrs['bar']['baz']['foo']
    #
    def maybe_nested_attribute(attribute_name, nested_under = nil)
      self.class.maybe_nested_attribute(@attrs, attribute_name, nested_under)
    end

    def self.maybe_nested_attribute(attributes, attribute_name, nested_under = nil)
      return attributes[attribute_name] if nested_under.nil?
      if nested_under.instance_of? Array
        final = nested_under.inject(attributes) do |parent, key|
          break if parent.nil?
          parent[key]
        end
        return nil if final.nil?
        final[attribute_name]
      else
        return attributes[nested_under][attribute_name]
      end
    end

    def url_with_query_params(url, query_params)
      uri = URI.parse(url)
      uri.query = uri.query.nil? ? "#{hash_to_query_string query_params}" : "#{uri.query}&#{hash_to_query_string query_params}" unless query_params.empty?
      uri.to_s
    end

    def hash_to_query_string(query_params)
      self.class.hash_to_query_string(query_params)
    end

    def self.hash_to_query_string(query_params)
      query_params.map do |k,v|
        CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s)
      end.join('&')
    end

    def self.query_params_for_single_fetch(options)
      Hash[options.select do |k,v|
        QUERY_PARAMS_FOR_SINGLE_FETCH.include? k
      end]
    end

    def self.query_params_for_search(options)
      Hash[options.select do |k,v|
        QUERY_PARAMS_FOR_SEARCH.include? k
      end]
    end
  end
end
