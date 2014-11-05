package 'git'
package 'nginx'
package 'php5'
package 'php5-fpm'
package 'php5-curl'

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action [:enable]
end

service 'php5-fpm' do
  supports :status => true, :restart => true, :reload => true
  provider Chef::Provider::Service::Upstart
  action [:enable]
end

domains = []

node[:apps].each do |name, params|

  apppath = "/home/#{node[:user]}/Develop/#{name}"
  domains << params[:domain]

  ['app', 'tmp', 'logs', 'sessions', 'config'].each do |dir|
    directory "#{apppath}/#{dir}" do
      owner node[:user]
      recursive true
    end
  end

  git "#{apppath}/app" do
    repository params[:git][:repo]
    revision params[:git][:branch]
    action :checkout
    user node[:user]
  end

  template "#{apppath}/config/#{name}.nginx.conf" do
    source "nginx.erb"
    mode '0644'
    owner node[:user]
    group node[:user]
    variables({
                  :rootpath => "#{apppath}/app",
                  :logspath => "#{apppath}/logs",
                  :fpmport => node[:fpm][:port],
                  :domain => "#{params[:domain]}",
              })
  end

  template "#{apppath}/config/#{name}.php-fpm.conf" do
    source "php-fpm.erb"
    mode '0644'
    owner node[:user]
    group node[:user]
    variables({
                  :homedir => "#{apppath}",
                  :rootpath => "#{apppath}/app",
                  :logspath => "#{apppath}/logs",
                  :tmppath => "#{apppath}/tmp",
                  :sessionspath => "#{apppath}/sessions",
                  :fpmport => node[:fpm][:port],
                  :fpmuser => node[:user],
                  :fpmgroup => node[:user],
                  :appname => name,
              })
    notifies :restart, "service[php5-fpm]", :delayed
  end

  link "/etc/nginx/sites-enabled/#{name}.conf" do
    to "#{apppath}/config/#{name}.nginx.conf"
    notifies :restart, "service[nginx]", :delayed
  end

  link "/etc/php5/fpm/pool.d/#{name}.conf" do
    to "#{apppath}/config/#{name}.php-fpm.conf"
    notifies :restart, "service[php5-fpm]", :delayed
  end
end

template "/etc/hosts" do
  source "hosts.erb"
  mode '0644'
  variables({
                :domains => domains
            })
end