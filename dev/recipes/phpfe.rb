package 'git'
package 'nginx'
package 'php5'
package 'php5-fpm'
package 'php5-curl'
package 'php5-gd'

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

  directory "#{apppath}" do
    user node[:user]
    owner node[:user]
    recursive true
    not_if {Dir.exists?("#{apppath}")}
  end

  ['tmp', 'logs', 'sessions', 'config'].each do |dir|
    directory "#{apppath}/#{dir}" do
      user node[:user]
      owner node[:user]
      recursive true
      not_if {Dir.exists?("#{apppath}/#{dir}")}
    end
  end

  bash "clone project" do
    user node[:user]
    cwd "#{apppath}"
    code <<-EOH
      git clone #{params[:git][:repo]} app
      cd app
      git checkout #{params[:git][:branch]}
      ln -s ../config
    EOH
    not_if {Dir.exists?("#{apppath}/app")}
  end

  template "#{apppath}/config/#{name}.nginx.conf" do
    source "nginx.erb"
    mode '0644'
    owner node[:user]
    group node[:user]
    variables({
                  :rootpath => "#{apppath}/app",
                  :logspath => "#{apppath}/logs",
                  :fpmport => params[:fpmport],
                  :domain => "#{params[:domain]}",
                  :adminpath => "#{apppath}/admin_frontend",
              })
  end

  template "#{apppath}/config/#{name}.php-fpm.conf" do
    source "php-fpm.erb"
    mode '0644'
    owner node[:user]
    group node[:user]
    variables({
                  :homedir => "#{apppath}",
                  :phppath => "#{apppath}/app",
                  :adminpath => "#{apppath}/admin",
                  :logspath => "#{apppath}/logs",
                  :tmppath => "#{apppath}/tmp",
                  :sessionspath => "#{apppath}/sessions",
                  :fpmport => params[:fpmport],
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