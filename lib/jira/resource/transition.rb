module JIRA
  module Resource

    class TransitionFactory < JIRA::BaseFactory # :nodoc:
    end

    class Transition < JIRA::Base
        nested_collections true

        def self.forIssue(client, issue_key)
          url = client.options[:rest_base_path] + "/issue/" + CGI.escape(issue_key) + "/transitions"
          response = client.get(url)
          json = parse_json(response.body)
          json['transitions'].map do |transition|
            client.Transition.build(transition)
          end
        end

        def transitionIssue(issue_key)
            url = client.options[:rest_base_path] + "/issue/" + CGI.escape(issue_key) + "/transitions"
            body = {"transition" => id}
            response = client.post(url, body.to_json)
        end
    end

  end
end
