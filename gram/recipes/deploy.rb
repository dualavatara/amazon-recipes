package 'git'
package 'nginx'
package 'php5'
package 'php5-fpm'

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable ]
end

service 'php5-fpm' do
  supports :status => true, :restart => true, :reload => true
  provider Chef::Provider::Service::Upstart
  action [ :enable ]
end

node[:deploy].each do |application, deploy|
  user application do
    home "/home/#{application}"
  end

  directory "/home/#{application}/.ssh" do
    owner application
    recursive true
  end

  ['shared', 'shared/tmp', 'shared/logs', 'shared/sessions', 'shared/config'].each do |dir|
    directory "/home/#{application}/#{dir}" do
      owner application
      recursive true
    end
  end

  file "/home/#{application}/.ssh/id_rsa" do
    owner application
    content deploy[:scm][:ssh_key]
    mode '0600'
    action :create
  end

  cookbook_file "/home/#{application}/wrap-ssh4git.sh" do
    source "wrap-ssh4git.sh"
    owner application
    mode '0700'
  end

  deploy "/home/#{application}" do
    repo deploy[:scm][:repository]
    user application
    migrate false
    purge_before_symlink ['tmp', 'logs', 'sessions', 'config']
    # create_dirs_before_symlink ['tmp', 'logs', 'sessions', 'config']
    create_dirs_before_symlink([])
    symlinks  "tmp"   => "tmp",
        "logs"   => "logs",
        "sessions" => "sessions",
        "config" => "config"

    enable_submodules true
    shallow_clone true
    keep_releases 5
    symlink_before_migrate({})
    action :deploy # or :rollback
    scm_provider Chef::Provider::Git # is the default, for svn: Chef::Provider::Subversion
    ssh_wrapper "/home/#{application}/wrap-ssh4git.sh"
  end

  template "/etc/nginx/sites-available/#{application}" do
    source "nginx.erb"
    mode '0644'
    owner 'root'
    group 'root'
    variables({
                  :rootpath => "/home/#{application}/current",
                  :logspath => "/home/#{application}/shared/logs",
                  :fpmport => node[:fpm][:port],
                  :domain => deploy[:domains].first,
              })
  end

  link "/etc/nginx/sites-enabled/#{application}" do
    to "/etc/nginx/sites-available/#{application}"
    notifies :restart, "service[nginx]", :delayed
  end

  template "/etc/php5/fpm/pool.d/#{application}.conf" do
    source "php-fpm.erb"
    mode '0644'
    owner 'root'
    group 'root'
    variables({
                  :rootpath => "/home/#{application}/current",
                  :logspath => "/home/#{application}/shared/logs",
                  :tmppath => "/home/#{application}/shared/tmp",
                  :sessionspath => "/home/#{application}/shared/sessions",
                  :fpmport => node[:fpm][:port],
                  :fpmuser => application,
                  :fpmgroup => application,
                  :appname => application,
              })
    notifies :restart, "service[php5-fpm]", :delayed
  end
end