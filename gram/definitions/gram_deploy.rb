define :gram_deploy, :domain => nil, :repo => nil, :revision => nil, :ssh_key => nil, :application => nil do
  params[:application] ||= params[:name]

  application = params[:application]

  user application do
    home "/home/#{application}"
  end

  directory "/home/#{application}/.ssh" do
    owner application
    recursive true
  end

  ['shared', 'shared/tmp', 'shared/logs', 'shared/sessions', 'shared/config', 'shared/vendor'].each do |dir|
    directory "/home/#{application}/#{dir}" do
      owner application
      recursive true
    end
  end

  file "/home/#{application}/.ssh/id_rsa" do
    owner application
    content params[:ssh_key]
    mode '0600'
    action :create
  end

  cookbook_file "/home/#{application}/wrap-ssh4git.sh" do
    source "wrap-ssh4git.sh"
    owner application
    mode '0700'
  end

  deploy_branch "/home/#{application}" do
    repo params[:repo]

    revision params[:revision]

    user application
    migrate false
    purge_before_symlink ['tmp', 'logs', 'sessions', 'config', 'vendor']
    create_dirs_before_symlink([])
    symlinks  "tmp"   => "tmp",
              "logs"   => "logs",
              "sessions" => "sessions",
              "config" => "config",
              "vendor" => "vendor"

    enable_submodules true
    shallow_clone false
    keep_releases 5
    symlink_before_migrate({})
    action :deploy # or :rollback
    scm_provider Chef::Provider::Git # is the default, for svn: Chef::Provider::Subversion
    ssh_wrapper "/home/#{application}/wrap-ssh4git.sh"

    before_restart do #run composer update
      bash 'composer update' do
        user application
        group application
        cwd "/home/#{application}/current"
        code <<-EOS
          private/composer.phar install
        EOS
      end
    end

    notifies :restart, "service[nginx]", :delayed
    notifies :restart, "service[php5-fpm]", :delayed
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
                  :domain => "#{params[:domain]}",
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
                  :homedir => "/home/#{application}",
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