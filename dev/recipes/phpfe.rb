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

fpm_port = 10000

node[:apps][:php].each do |name, params|

  apppath = "/home/#{node[:user]}/Develop/#{name}"

  app_dir apppath do
    user node[:user]
    repo params[:git][:repo]
    branch params[:git][:branch]
    dirs ['tmp', 'logs', 'sessions', 'config']
  end

  php name do
    apppath apppath
    user node[:user]
    domain params[:domain]
    fpmport fpm_port
  end

  fpm_port += 1
end