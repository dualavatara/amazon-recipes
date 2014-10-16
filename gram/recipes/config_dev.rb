service 'nginx' do
  supports :status => true, :restart => true, :reload => true
end

service 'php5-fpm' do
  supports :status => true, :restart => true, :reload => true
  provider Chef::Provider::Service::Upstart
end

node[:deploy].each do |application, deploy|
  template "/home/#{application}/shared/config/dirtygram.yml" do
    source "dirtygram.yml.erb"
    mode '0644'
    owner application
    variables({
                  :port => node[:dynamodb][:port],
                  :dbname => application,
                  :cdn_bucket => "cdn.test.#{deploy[:domains].first}",
                  :cdn_url => "http://cdn.test.#{deploy[:domains].first}.s3-eu-west-1.amazonaws.com/",
                  :fb_app_id => node[:facebook][:app_id],
                  :fb_app_secret => node[:facebook][:app_secret]
              })
    not_if {File.exists?("/home/#{application}/shared/config/dirtygram.yml")}
    notifies :restart, "service[nginx]", :delayed
    notifies :restart, "service[php5-fpm]", :delayed
  end
end