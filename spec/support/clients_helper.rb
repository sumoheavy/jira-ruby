module ClientsHelper
  def with_each_client
    clients = {}

    oauth_client = JIRA::Client.new({ :consumer_key => 'foo', :consumer_secret => 'bar' })
    oauth_client.set_access_token('abc', '123')
    clients["http://localhost:2990"] = oauth_client

    basic_client = JIRA::Client.new({ :username => 'foo', :password => 'bar', :auth_type => :basic, :use_ssl => false })
    clients["http://foo:bar@localhost:2990"] = basic_client

    clients.each do |site_url, client|
      yield site_url, client
    end
  end
end
