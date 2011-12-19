module JIRA
  module Resource

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
        # So create a method chain from the class componenets.  This code will
        # unroll to:
        #   Module.const_get('JIRA').const_get('Resource').const_get('Foo')
        #
        target_class_name = self.class.name.sub(/Factory$/, '')
        class_components = target_class_name.split('::')

        class_components.inject(Module) do |mod, const_name|
          mod.const_get(const_name)
        end
      end

      def all
        target_class.all(@client)
      end

      def find(key)
        target_class.find(@client, key)
      end

      def build(attrs={})
        target_class.build(@client, attrs)
      end
    end
  end
end
