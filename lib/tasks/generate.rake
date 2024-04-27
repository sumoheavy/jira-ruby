require 'securerandom'

namespace :jira do
  desc 'Generate a consumer key for your application'
  task :generate_consumer_key do
    key = SecureRandom.hex(16)
    puts "You can use this as your consumer key: #{key}"
  end

  desc 'Run the system call to generate a RSA public certificate'
  task :generate_public_cert do
    puts "Executing 'openssl req -x509 -nodes -newkey rsa:1024 -sha1 -keyout rsakey.pem -out rsacert.pem'"
    system('openssl req -x509 -subj "/C=US/ST=New York/L=New York/O=SUMO Heavy Industries/CN=www.sumoheavy.com" -nodes -newkey rsa:1024 -sha1 -keyout rsakey.pem -out rsacert.pem')
    puts "Done. The RSA-SHA1 private keyfile is in the current directory: \'rsakey.pem\'."
    puts 'You will need to copy the following certificate into your application link configuration in Jira:'
    system('cat rsacert.pem')
  end
end
