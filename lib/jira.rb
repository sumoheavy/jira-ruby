Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f } if defined?(Rake)

$: << File.expand_path(File.dirname(__FILE__))
require 'jira/resource/base'
require 'jira/resource/base_factory'
require 'jira/resource/http_error'

require 'jira/resource/issue'
require 'jira/resource/project'
require 'jira/resource/component'

require 'jira/client'
