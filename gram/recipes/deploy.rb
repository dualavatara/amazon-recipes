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

node[:deploy].each do |application, deploy|
  node[:opsworks][:instance][:layers].each do | layername |

    gram_deploy application do
      domain node[layername][:domain]
      repo deploy[:scm][:repository]
      revision node[layername][:branch]
      ssh_key deploy[:scm][:ssh_key]
    end

  end
end