define :old_config do
  params[:application] ||= params[:name]
  application = params[:application]
  domain = params[:domain]

  template "/home/#{application}/shared/config/LocalConfig.php" do
    source "LocalConfig.php.erb"
    mode '0644'
    owner application
    variables({
                  :port => node[:dynamodb][:port],
                  :dbname => application,
                  :deploy_path => "/home/#{application}/current",
                  :deploy_host => "http://#{domain}",
                  :deploy_domain => "#{domain}",
                  :fb_app_id => node[:facebook][:app_id],
                  :fb_app_secret => node[:facebook][:app_secret]
              })
    not_if {File.exists?("/home/#{application}/shared/config/LocalConfig.php")}
  end
end