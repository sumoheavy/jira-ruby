begin
  require 'rails/railtie'
rescue LoadError
else
module JIRA
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/generate.rake'
    end
  end
end
end
