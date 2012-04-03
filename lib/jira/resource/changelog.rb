module JIRA
  module Resource

    class ChangelogFactory < JIRA::BaseFactory # :nodoc:
    end

    class Changelog < JIRA::Base
      nested_collections true
      has_one :author, :class => JIRA::Resource::User
      has_many :items, :class => String
    end

  end
end
