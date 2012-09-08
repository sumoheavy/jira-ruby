module JIRA
  module Resource

    class AttachmentFactory < JIRA::BaseFactory # :nodoc:
    end

    class Attachment < JIRA::Base
      has_one :author, :class => JIRA::Resource::User
      belongs_to :issue
      nested_collections true
    end

  end
end
