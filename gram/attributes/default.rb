default[:dynamodb][:url] = "https://s3-eu-west-1.amazonaws.com/pandra-service/dynamodb_local.tar.gz"
default[:dynamodb][:path] = "/usr/local/dynamodb"
default[:dynamodb][:port] = "8000"
default[:dynamodb][:dbpath] = "/var/local/dynamodb"
default[:fpm][:port] = "10000"
default[:facebook][:app_id] = ""
default[:facebook][:app_secret] = ""
default[:layers] = {
    :web_fe => {
        :branch => 'master',
        :domain => 'dirtygram.pandra.ru'
    },
    :web_fe_test => {
        :branch => 'develop',
        :domain => 'test.dirtygram.pandra.ru'
    }
}