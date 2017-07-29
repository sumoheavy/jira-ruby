module JIRA

  # This is the base class for all the JIRA resource factory instances.
  class BaseFactory

    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Return the name of the class which this factory generates, i.e.
    # JIRA::Resource::FooFactory creates JIRA::Resource::Foo instances.
    def target_class
      # Need to do a little bit of work here as Module.const_get doesn't work
      # with nested class names, i.e. JIRA::Resource::Foo.
      #
      # So create a method chain from the class components.  This code will
      # unroll to:
      #   Module.const_get('JIRA').const_get('Resource').const_get('Foo')
      #
      target_class_name = self.class.name.sub(/Factory$/, '')
      class_components = target_class_name.split('::')

      class_components.inject(Module) do |mod, const_name|
        mod.const_get(const_name)
      end
    end

    def self.delegate_to_target_class(*method_names)
      method_names.each do |method_name|
        define_method method_name do |*args|
          target_class.send(method_name, @client, *args)
        end
      end
    end

    # The principle purpose of this class is to delegate methods to the corresponding
    # non-factory class and automatically prepend the client argument to the argument
    # list.
    delegate_to_target_class :all, :find, :collection_path, :singular_path, :jql, :get_backlog_issues, :get_board_issues, :get_sprints, :get_sprint_issues, :get_projects, :get_projects_full

    # This method needs special handling as it has a default argument value
    def build(attrs={})
      target_class.build(@client, attrs)
    end

  end
end
