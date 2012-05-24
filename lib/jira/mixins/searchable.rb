module JIRA
 module Mixins
  module Searchable

   def build_search_uri(client,jql,next_result)
     url = client.options[:rest_base_path] + "/search?startAt=#{next_result}"
     url << "&jql=#{ URI.escape(jql) }" if jql
     JIRA::Log.debug ":search_uri => #{url}"
     url
   end

   def page_jql(client, jql, &block)
    items = []
    fetched_results = 0
    begin
      JIRA::Log.debug ":fetched_results => #{fetched_results}" 
      url = build_search_uri(client,jql,fetched_results)

      response = client.get(url)
      json = parse_json(response.body)

      JIRA::Log.debug ":max_results => #{json['maxResults']}"
      JIRA::Log.debug ":total_results => #{json['total']}"
      if block_given?
        json['issues'].map do |item|
          yield client.Issue.build(item)
        end
      else
        items = items + json['issues'].map do |item|
          client.Issue.build(item)
        end
      end

      fetched_results += json['maxResults']

    end while fetched_results < json['total']

    block_given? ? nil : items 
   end

   def get_scoped_jql(object,jql = nil)
    jql ||= ''
    jql << " " unless (jql[-1].eql? " " or jql.eql? '')
    jql << "#{object.class.endpoint_name}='#{object.key_value}'"
    JIRA::Log.debug ":scoped_jql => #{jql}"
    jql 
   end

  end
 end
end