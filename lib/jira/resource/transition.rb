module JIRA
  module Resource

    class TransitionFactory < JIRA::BaseFactory # :nodoc:
    end

    class Transition < JIRA::Base
      belongs_to :issue

      def url
        "#{@issue.self}/transitions"
      end
    end

  end
end