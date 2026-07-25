# These resource classes are test fixtures.
#
# You must not change these class names. JIRA::Base finds the target of a
# `has_one`, a `has_many`, or a `belongs_to` from the class name. Also,
# JIRA::BaseFactory#target_class removes "Factory" from its own name to find its
# target.
module JIRA
  module Resource
    class Deadbeef < JIRA::Base # :nodoc:
    end

    class HasOneExample < JIRA::Base # :nodoc:
      has_one :deadbeef
      has_one :muffin, class: JIRA::Resource::Deadbeef
      has_one :brunchmuffin, class: JIRA::Resource::Deadbeef,
                             nested_under: 'nested'
      has_one :breakfastscone,
              class: JIRA::Resource::Deadbeef,
              nested_under: %w[nested breakfastscone]
      has_one :irregularly_named_thing,
              class: JIRA::Resource::Deadbeef,
              attribute_key: 'irregularlyNamedThing'
    end

    class HasManyExample < JIRA::Base # :nodoc:
      has_many :deadbeefs
      has_many :brunchmuffins, class: JIRA::Resource::Deadbeef,
                               nested_under: 'nested'
      has_many :breakfastscones,
               class: JIRA::Resource::Deadbeef,
               nested_under: %w[nested breakfastscone]
      has_many :irregularly_named_things,
               class: JIRA::Resource::Deadbeef,
               attribute_key: 'irregularlyNamedThings'
    end

    class BelongsToExample < JIRA::Base # :nodoc:
      belongs_to :deadbeef
    end

    # This class is the target of FooFactory. It tests the factory delegation.
    class Foo < JIRA::Base; end

    class FooFactory < JIRA::BaseFactory; end
  end
end

# This class is a target class for a HasManyProxy. It is not the same as the
# JIRA::Resource::Foo class above. The tests replace all calls to this class with
# stubs. Thus the class does not need a body.
class Foo < JIRA::Base; end
