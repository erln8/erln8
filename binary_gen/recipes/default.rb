#
# Cookbook Name:: binary_gen
# Recipe:: default
#
# Copyright (c) 2015 Dave Parfitt, All Rights Reserved.
if ( !::File.exist?('/var/lib/apt/periodic/update-success-stamp') )
  e = bash 'apt-get-update at compile time' do
    code <<-EOH
      apt-get update
    EOH
    ignore_failure true
    action :nothing
  end
  e.run_action(:run)
end

remote_file "/#{node["binary_gen"]["dmd_filename"]}" do
  source "#{node["binary_gen"]["dmd_url"]}"
end

remote_file "/#{node["binary_gen"]["dub_filename"]}" do
  source "#{node["binary_gen"]["dub_url"]}"
end

package ["libcurl3", "xdg-utils", "gcc", "git"] do
  action :install
end

dpkg_package "install" do
  action :install
  source "/#{node["binary_gen"]["dmd_filename"]}"
end

git "/root/reo" do
  repository node["binary_gen"]["git_repository"]
  #revision node[:app_name][:git_revision]
  action :sync
  #notifies :run, "bash[compile_app_name]"
end

d = bash 'install dub and build reo' do
   code <<-EOH
     tar xzvf #{node["binary_gen"]["dub_filename"]}
     cp dub /usr/bin/dub
     cd /root/reo
     dub build
   EOH
   action :nothing
end
d.run_action(:run)

