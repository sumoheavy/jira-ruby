require 'cgi'
require 'json'
ENV['WORKLOG_VERBOSE_FETCH'] = nil
conns = ActiveUserConnections.new.go! 
conn = conns.find {|s| s.client.options[:auth_type] == :oauth}
conn.worklogs_modified_since(1.month.ago) rescue (puts $!.to_yaml; puts 'pooooo')

class JIRA::Base 
  def self.hash_to_query_string(query_params)
    puts '-- hash to query string'
    query_string = query_params.map do |k, v|
      next if k.in?(['jql', :jql])
      CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s)
    end.compact.join('&')
    some_jql = query_params['jql'] || query_params[:jql]
    if some_jql 
      [query_string.presence,"jql=#{CGI.escape(some_jql.to_s)}"].join('&')
    else
      query_string 
    end 
  end
end 
class JIRA::OauthClient 
  def init_oauth_consumer(_options)
    puts '--- init oauth consumer'
    puts @options.to_yaml
    @options[:request_token_path] = @options[:context_path] + @options[:request_token_path]
    @options[:authorize_path] = @options[:context_path] + @options[:authorize_path]
    @options[:access_token_path] = @options[:context_path] + @options[:access_token_path]
    OAuth::Consumer.new(@options[:consumer_key], @options[:consumer_secret], @options)
  end

  # Returns the current request token if it is set, else it creates
  # and sets a new token.
  def request_token(options = {}, *arguments, &block)
  puts '--- request token'
  puts options.to_yaml
    @request_token ||= get_request_token(options, *arguments, block)
  end

  # Sets the request token from a given token and secret.
  def set_request_token(token, secret)
    puts '--- set request token'
    puts token 
    puts secret
    @request_token = OAuth::RequestToken.new(@consumer, token, secret)
  end

  # Initialises and returns a new access token from the params hash
  # returned by the OAuth transaction.
  def init_access_token(params)
    puts '--- Init Access Token'
    puts params.to_yaml
    @access_token = request_token.get_access_token(params)
  end

  # Sets the access token from a preexisting token and secret.
  def set_access_token(token, secret)
    puts '---Set Access Token'
    puts token 
    puts secret
    @access_token = OAuth::AccessToken.new(@consumer, token, secret)
    @authenticated = true
    @access_token
  end

  # Returns the current access token. Raises an
  # JIRA::Client::UninitializedAccessTokenError exception if it is not set.
  def access_token
    puts '--- access token'
    raise UninitializedAccessTokenError unless @access_token
    @access_token
  end

  def make_request(http_method, path, body = '', headers = {})
    # When using oauth_2legged we need to add an empty oauth_token parameter to every request.
    if @options[:auth_type] == :oauth_2legged
      oauth_params_str = 'oauth_token='
      uri = URI.parse(path)
      uri.query = if uri.query.to_s == ''
                    oauth_params_str
                  else
                    uri.query + '&' + oauth_params_str
                  end
      path = uri.to_s
    end

    case http_method
    when :delete, :get, :head
      puts '--- make_request'
      puts access_token.class.name
      puts access_token.to_yaml.to_s.length
      puts http_method.to_yaml 
      puts path.to_yaml 
      puts headers.to_yaml 
      path.gsub!('?&','?')
      puts 'NEW PATH'
      puts path.to_yaml 
      response = access_token.send http_method, path, headers
      if response.body == "oauth_problem=nonce_used"
        byebug
        # byebug
        # @access_token = OAuth::AccessToken.new(@consumer, access_token.token, access_token.secret)
        # byebug
        # response = access_token.send http_method, path, headers
      else  
        puts '=== REQUEST WAS OK!1!!'
      end 
      
    when :post, :put
      response = access_token.send http_method, path, body, headers
    end

    @authenticated = true
    response
  end

end 
class JIRA::Resource::Worklog 
  def self.rehydrate_worklog_issues_for_worklogs(client, worklawgs)
    worklogs_by_issue = worklawgs.group_by {|worklog| worklog.issue.id }
    worklog_issue_ids = worklogs_by_issue.keys.compact
    vputs 'rehydrating issues'
    rehydrated = 0

    issue_batch_size = 
      case client.request_client 
      when JIRA::OauthClient
        25 
      else 
        100 
      end 

      issues =
      worklog_issue_ids.each_slice(25).map do |the_issue_ids|
        rehydrated += the_issue_ids.count
        vputs 'Rehydrated issue count'
        vputs rehydrated 
        vputs 'of' 
        vputs worklog_issue_ids.count
        puts 'REEEEEEEHYDRATING!!!!!!!!'
        client.Issue.jql("id IN (#{the_issue_ids.join(',')})")
        puts 'DOOOOONE WITH LOOKUP'
      end.compact.flatten

    missing_issue_ids = worklog_issue_ids - (issues.map(&:id))
    if missing_issue_ids.count.positive?
      vputs "MISSING #{missing_issue_ids.count} out of #{worklog_issue_ids.count} issues during lookup" 
      vputs "They will be retrieved manually during worklog storage"
    end
    worklogs_by_issue.map do |issue_id, worklogs|
      found_issue = issues.find {|issue| issue.id == issue_id }
      the_issue = case
        when found_issue
          found_issue
        else
          # iss = 
            # begin 
            #  vputs 'fetching issue with id'
            #  vputs issue_id
            #   client.Issue.find(issue_id)
            # rescue 
            #  vputs "There was an issue retrieving the issue with id #{issue_id}"
            #  vputs $!.message.first(100)
            #  vputs $!.backtrace.first(50)

              iz = JIRA::Resource::Issue.new(
                client,
                :attrs => {'id' => issue_id }
              )
              # iz.instance_variable_set('@deleted', true)
              iz  
          #   end 
          # iss
        end

      worklogs.map do |worklog|
        self.new(
          client,
          {
            :attrs => worklog.attrs,
            :issue => the_issue
          }
        )
      end
    end.flatten
  end

end 

class JIRA::Resource::Issue 
  def self.jql(client, jql, options = { fields: nil, start_at: nil, max_results: nil, expand: nil, validate_query: true, autopaginate: true })
    puts "================= JQL OUTER"
    puts options.to_yaml
    search_url = client.options[:rest_base_path] + '/search'
    query_params = { jql: jql }
    query_params.update(fields: options[:fields].map { |value| client.Field.name_to_id(value) }.join(',')) if options[:fields]
    query_params.update(startAt: options[:start_at].to_s) if options[:start_at]
    query_params.update(maxResults: options[:max_results].to_s) if options[:max_results]
    query_params.update(validateQuery: 'false') if options[:validate_query] === false
    if options[:expand]
      options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
      query_params.update(expand: options[:expand].to_a.join(','))
    end
    puts '===== PRE Q'
    puts url_with_query_params(search_url, query_params).to_yaml
    puts '====== ABOUT TO GOOO'
    response = client.get(url_with_query_params(search_url, query_params))
    puts '===== WEEEEENT'
    json = parse_json(response.body)
    puts json.slice('startAt', 'maxResults', 'lastPage', 'total').to_yaml
    if options[:max_results] && (options[:max_results] == 0)
      return json['total']
    end

    result_issues = json['issues']

    autopaginate = options[:autopaginate]
    if autopaginate 
      while (json['startAt'] + json['maxResults']) < json['total']
        puts "=== == = = = JQL INNER"
        query_params['startAt'] = (json['startAt'] + json['maxResults'])
        puts url_with_query_params(search_url, query_params).to_yaml

        response = client.get(url_with_query_params(search_url, query_params))
        json = parse_json(response.body)
        result_issues += json['issues']
        puts json.slice('startAt', 'maxResults', 'lastPage', 'total').to_yaml
 
      end
    end

    result_issues.map do |issue|
      client.Issue.build(issue)
    end
  end
end 

module JIRA
  module Resource
    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base
      has_one :reporter,  class: JIRA::Resource::User,
                          nested_under: 'fields'
      has_one :assignee,  class: JIRA::Resource::User,
                          nested_under: 'fields'
      has_one :project,   nested_under: 'fields'

      has_one :issuetype, nested_under: 'fields'

      has_one :priority,  nested_under: 'fields'

      has_one :status,    nested_under: 'fields'

      has_many :transitions
      has_many :worklogs
      has_many :changelogs

      has_many :components, nested_under: 'fields'

      has_many :comments, nested_under: %w[fields comment]

      has_many :attachments, nested_under: 'fields',
                             attribute_key: 'attachment'

      has_many :versions,    nested_under: 'fields'
      has_many :fixVersions, class: JIRA::Resource::Version,
                             nested_under: 'fields'


      has_one :sprint, class: JIRA::Resource::Sprint,
                       nested_under: 'fields'

      has_many :closed_sprints, class: JIRA::Resource::Sprint,
                                nested_under: 'fields', attribute_key: 'closedSprints'

      has_many :issuelinks, nested_under: 'fields'

      has_many :remotelink, class: JIRA::Resource::Remotelink

      has_many :watchers,   attribute_key: 'watches',
                            nested_under: %w[fields watches]

      def self.all(client)
        start_at = 0
        max_results = 1000
        result = []
        loop do
          url = client.options[:rest_base_path] +
                "/search?expand=transitions.fields&maxResults=#{max_results}&startAt=#{start_at}"
          response = client.get(url)
          json = parse_json(response.body)
          json['issues'].map do |issue|
            result.push(client.Issue.build(issue))
          end
          break if json['issues'].empty?
          start_at += json['issues'].size
        end
        result
      end

      def self.jql(client, jql, options = { fields: nil, start_at: nil, max_results: nil, expand: nil, validate_query: true, autopaginate: true })
        search_url = client.options[:rest_base_path] + '/search'
        query_params = { jql: jql }
        query_params.update(fields: options[:fields].map { |value| client.Field.name_to_id(value) }.join(',')) if options[:fields]
        query_params.update(startAt: options[:start_at].to_s) if options[:start_at]
        query_params.update(maxResults: options[:max_results].to_s) if options[:max_results]
        query_params.update(validateQuery: 'false') if options[:validate_query] === false
        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          query_params.update(expand: options[:expand].to_a.join(','))
        end

        response = client.get(url_with_query_params(search_url, query_params))

        json = parse_json(response.body)
        if options[:max_results] && (options[:max_results] == 0)
          return json['total']
        end

        result_issues = json['issues']

        autopaginate = options[:autopaginate]
        if autopaginate
          while (json['startAt'] + json['maxResults']) < json['total']
            query_params['startAt'] = (json['startAt'] + json['maxResults'])
            response = client.get(url_with_query_params(search_url, query_params))
            json = parse_json(response.body)
            result_issues += json['issues']
          end
        end

        result_issues.map do |issue|
          client.Issue.build(issue)
        end
      end


      # Fetches the attributes for the specified resource from JIRA unless
      # the resource is already expanded and the optional force reload flag
      # is not set
      def fetch(reload = false, query_params = {})
        return if expanded? && !reload
        response = client.get(url_with_query_params(url, query_params))
        set_attrs_from_response(response)
        if @attrs && @attrs['fields'] && @attrs['fields']['worklog'] && (@attrs['fields']['worklog']['total'] > @attrs['fields']['worklog']['maxResults'])
          worklog_url = client.options[:rest_base_path] + "/#{self.class.endpoint_name}/#{id}/worklog"
          response = client.get(worklog_url)
          unless response.body.nil? || (response.body.length < 2)
            set_attrs({ 'fields' => { 'worklog' => self.class.parse_json(response.body) } }, false)
          end
        end
        @expanded = true
      end

      def editmeta
        editmeta_url = client.options[:rest_base_path] + "/#{self.class.endpoint_name}/#{key}/editmeta"

        response = client.get(editmeta_url)
        json = self.class.parse_json(response.body)
        json['fields']
      end

      def respond_to?(method_name, _include_all = false)
        if attrs.key?('fields') && [method_name.to_s, client.Field.name_to_id(method_name)].any? { |k| attrs['fields'].key?(k) }
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.key?('fields')
          if attrs['fields'].key?(method_name.to_s)
            attrs['fields'][method_name.to_s]
          else
            official_name = client.Field.name_to_id(method_name)
            if attrs['fields'].key?(official_name)
              attrs['fields'][official_name]
            else
              super(method_name, *args, &block)
            end
          end
        else
          super(method_name, *args, &block)
        end
      end
    end
  end
end
