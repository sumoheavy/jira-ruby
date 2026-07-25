# Resource classes used as test fixtures.
#
# JIRA::Base resolves has_one/has_many/belongs_to targets from class names, and
# JIRA::BaseFactory#target_class derives its target by stripping "Factory" from its
# own name, so these must keep their fully qualified names.
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

    # Target of FooFactory, used to verify factory delegation.
    class Foo < JIRA::Base; end

    class FooFactory < JIRA::BaseFactory; end
  end
end

# Stands in for a HasManyProxy target class. Distinct from JIRA::Resource::Foo above.
# Every call made on it is stubbed, so it needs no body of its own.
class Foo < JIRA::Base; end
