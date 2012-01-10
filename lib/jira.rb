$: << File.expand_path(File.dirname(__FILE__))
require 'jira/resource/base'
require 'jira/resource/base_factory'
require 'jira/resource/http_error'

require 'jira/resource/user'
require 'jira/resource/component'
require 'jira/resource/project'
require 'jira/resource/issuetype'
require 'jira/resource/priority'
require 'jira/resource/issue'

require 'jira/client'
