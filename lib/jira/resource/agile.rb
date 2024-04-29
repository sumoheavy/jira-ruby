# frozen_string_literal: true

require 'cgi'

module JIRA
  module Resource
    class AgileFactory < JIRA::BaseFactory # :nodoc:
    end

    class Agile < JIRA::Base
      # @param client [JIRA::Client]
      # @param options [Hash<Symbol, Object>]
      # @return [Hash]
      def self.all(client, options = {})
        opts = options.empty? ? '' : "?#{hash_to_query_string(options)}"
        response = client.get(path_base(client) + "/board#{opts}")
        parse_json(response.body)
      end

      def self.get_backlog_issues(client, board_id, options = {})
        options[:maxResults] ||= 100
        response = client.get(path_base(client) + "/board/#{board_id}/backlog?#{hash_to_query_string(options)}")
        parse_json(response.body)
      end

      def self.get_board_issues(client, board_id, options = {})
        response = client.get(path_base(client) + "/board/#{board_id}/issue?#{hash_to_query_string(options)}")
        json = parse_json(response.body)
        # To get Issue objects with the same structure as for Issue.all
        return {} if json['issues'].empty?

        issue_ids = json['issues'].map do |issue|
          issue['id']
        end
        client.Issue.jql("id IN(#{issue_ids.join(', ')})")
      end

      def self.get_sprints(client, board_id, options = {})
        options[:maxResults] ||= 100
        response = client.get(path_base(client) + "/board/#{board_id}/sprint?#{hash_to_query_string(options)}")
        parse_json(response.body)
      end

      def self.get_sprint_issues(client, sprint_id, options = {})
        options[:maxResults] ||= 100
        response = client.get(path_base(client) + "/sprint/#{sprint_id}/issue?#{hash_to_query_string(options)}")
        parse_json(response.body)
      end

      def self.get_projects_full(client, board_id, _options = {})
        response = client.get(path_base(client) + "/board/#{board_id}/project/full")
        parse_json(response.body)
      end

      def self.get_projects(client, board_id, options = {})
        options[:maxResults] ||= 100
        create_meta_url = path_base(client) + "/board/#{board_id}/project"
        params = hash_to_query_string(options)

        response = client.get("#{create_meta_url}?#{params}")
        parse_json(response.body)
      end

      private

      def self.path_base(client)
        "#{client.options[:context_path]}/rest/agile/1.0"
      end

      def path_base(client)
        self.class.path_base(client)
      end

      private_class_method :path_base
    end
  end
end
