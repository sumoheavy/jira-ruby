namespace :jira_api do
  desc "Generate a consumer key for your application"
  task :generate_consumer_key do
    #FIXME SERIOUSLY. THIS IS NOT A REAL SOLUTION. I FEEL SO UNCLEAN.
    system("for i in {1..10}; do echo $RANDOM$RANDOM$RANDOM; done | md5 | awk '{ print \"You can use this as your consumer key: \" $0 }'")
  end

  desc "Run the system call to generate a RSA public certificate"
  task :generate_public_cert do
    puts "Executing 'openssl req -x509 -nodes -newkey rsa:1024 -sha1 -keyout myrsakey.pem -out myrsacert.pem'"
    system("openssl req -x509 -nodes -newkey rsa:1024 -sha1 -keyout rsakey.pem -out rsacert.pem")
    system("cat rsacert.pem")
    puts "Done. The RSA-SHA1 private keyfile is in the current directory: \'rsakey.pem\'."
    rm 'rsakey.pem'
  end
end
