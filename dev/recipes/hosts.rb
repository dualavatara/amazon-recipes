template "/etc/hosts" do
  source "hosts.erb"
  mode '0644'
  variables({
                :domains => node[:hosts]
            })
end