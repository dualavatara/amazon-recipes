package 'git'
package 'nginx'

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action [:enable]
end

rackport = 11000

node[:apps][:ruby].each do |name, params|

  apppath = "/home/#{node[:user]}/Develop/#{name}"

  app_dir apppath do
    user node[:user]
    repo params[:git][:repo]
    branch params[:git][:branch]
    dirs ['tmp', 'logs', 'sessions', 'config']
  end

  ruby name do
    apppath apppath
    user node[:user]
    domain params[:domain]
    port rackport
  end

  rackport += 1
end