gem 'wdm', '>= 0.1.0' if Gem.win_platform?
gem 'rspec', '~> 3.0.0'

guard 'rspec', cmd: 'bundle exec rspec --color --format doc' do
  # watch /lib/ files
  watch(%r{^lib/(.+).rb$}) do |m|
    "spec/#{m[1]}_spec.rb"
  end

  # watch /spec/ files
  watch(%r{^spec/(.+).rb$}) do |m|
    "spec/#{m[1]}.rb"
  end
end
