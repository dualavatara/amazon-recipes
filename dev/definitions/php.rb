define :php, :apppath => nil, :user => nil, :domain => nil, :fpmport => nil do
  apppath = params[:apppath]
  name = params[:name]

  template "#{apppath}/config/#{name}.nginx.conf" do
    source "nginx.php.erb"
    mode '0644'
    owner params[:user]
    group params[:user]
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
    owner params[:user]
    group params[:user]
    variables({
                  :homedir => "#{apppath}",
                  :phppath => "#{apppath}/app",
                  :adminpath => "#{apppath}/admin",
                  :logspath => "#{apppath}/logs",
                  :tmppath => "#{apppath}/tmp",
                  :sessionspath => "#{apppath}/sessions",
                  :fpmport => params[:fpmport],
                  :fpmuser => params[:user],
                  :fpmgroup => params[:user],
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