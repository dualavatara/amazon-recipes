 define :app_dir, :apppath => nil, :user => nil, :repo => nil, :branch => nil, :dirs => nil do
  params[:apppath] ||= params[:name]

  apppath = params[:apppath]

  directory "#{apppath}" do
    user params[:user]
    owner params[:user]
    recursive true
    not_if { Dir.exists?("#{apppath}") }
  end

  params[:dirs].each do |dir|
    directory "#{apppath}/#{dir}" do
      user params[:user]
      owner params[:user]
      recursive true
      not_if { Dir.exists?("#{apppath}/#{dir}") }
    end
  end

  bash "clone project" do
    user params[:user]
    cwd "#{apppath}"
    code <<-EOH
      git clone #{params[:repo]} app
      cd app
      git checkout #{params[:branch]}
      ln -s ../config
    EOH
    not_if { Dir.exists?("#{apppath}/app") }
  end

end