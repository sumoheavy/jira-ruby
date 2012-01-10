$: << File.expand_path(File.dirname(__FILE__))

require 'active_support/inflector'
ActiveSupport::Inflector.inflections do |inflector|
  inflector.singular 'status', 'status'
end

require 'jira/resource/base'
require 'jira/resource/base_factory'
require 'jira/resource/http_error'

require 'jira/resource/user'
require 'jira/resource/attachment'
require 'jira/resource/component'
require 'jira/resource/issuetype'
require 'jira/resource/version'
require 'jira/resource/project'
require 'jira/resource/priority'
require 'jira/resource/status'
require 'jira/resource/comment'
require 'jira/resource/issue'

require 'jira/client'

