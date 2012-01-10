module JIRA
  module Resource

    class AttachmentFactory < BaseFactory ; end

    class Attachment < Base
      has_one :author, :class => JIRA::Resource::User
    end

  end
end
