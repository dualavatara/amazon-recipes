package 'default-jre'

remote_file "#{Chef::Config[:file_cache_path]}/dynamodb_local.tar.gz" do
  source "#{node[:dynamodb][:url]}"
end

bash 'extract tar' do
  user 'root'
  group 'root'
  code <<-EOS

    mkdir -p #{node[:dynamodb][:path]}
    mkdir -p #{node[:dynamodb][:dbpath]}
    tar xzf #{Chef::Config[:file_cache_path]}/dynamodb_local.tar.gz -C #{node[:dynamodb][:path]} --strip-components=1

  EOS
end

template "/etc/init.d/dynamodb" do
  source "dyndb_servicescript.erb"
  mode '0755'
  owner 'root'
  group 'root'
  variables({
                :path => node[:dynamodb][:path],
                :port => node[:dynamodb][:port],
                :dbpath => node[:dynamodb][:dbpath],
            })
end

service 'dynamodb' do
  supports :status => true, :restart => true
  action [ :enable, :start ]
end

