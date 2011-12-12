module Jira
  module Resource

    # This is the base class for all the Jira resource factory instances.
    class BaseFactory

      attr_reader :client

      def initialize(client)
        @client = client
      end

      # This method assumes all target classes are within the
      # Jira::Resource module.
      def target_class
        # The last component of the module name, i.e. 'FooFactory' for
        # 'Jira::Resource::FooFactory'
        factory_base_name = self.class.name.split('::').last

        # Split Factory from the end of the class name
        base_name = factory_base_name.sub(/Factory$/, '')

        # Need to do this little hack because const_get does not work with
        # nested class names, e.g. const_get('Foo::Bar') will not work.
        Module.const_get('Jira').const_get('Resource').const_get(base_name)
      end

      def all
        target_class.all(@client)
      end

      def find(key)
        target_class.find(@client, key)
      end
    end
  end
end
