define :ruby, :apppath => nil, :user => nil, :domain => nil, :port => nil do
  apppath = params[:apppath]
  name = params[:name]

  template "#{apppath}/config/#{name}.nginx.conf" do
    source "nginx.ruby.erb"
    mode '0644'
    owner params[:user]
    group params[:user]
    variables({
                  :rootpath => "#{apppath}/app",
                  :logspath => "#{apppath}/logs",
                  :port => params[:port],
                  :domain => "#{params[:domain]}",
                  :adminpath => "#{apppath}/admin_frontend",
              })
  end

  link "/etc/nginx/sites-enabled/#{name}.conf" do
    to "#{apppath}/config/#{name}.nginx.conf"
    notifies :restart, "service[nginx]", :delayed
  end

  # create rack startup script for application

  template "/etc/init.d/rack-#{name}" do
    source "rack_service.erb"
    mode '0755'
    owner 'root'
    group 'root'
    variables({
                  :name => "rack-#{name}",
                  :apppath => apppath,
                  :port => params[:port]
              })
  end

  bash 'bundler install' do
    user 'root'
    group 'root'
    cwd "#{apppath}/app"
    code <<-EOS
          bundler install
    EOS
  end

  # bash "register service rack-#{name}" do
  #   user 'root'
  #   group 'root'
  #   code <<-EOS
  #   update-rc.d rack-#{name} start 70 2 3 4 5 . stop 20 0 1 6 .
  #   EOS
  # end

  service "rack-#{name}" do
    supports :status => true, :restart => true
    action [ :enable, :start ]
  end

end